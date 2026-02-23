//
//  BlikViewController.swift
//  MSDKDemo
//
//  Created by Arora, Yogesh on 06/03/25.
//  Copyright © 2025 ACI. All rights reserved.
//

import Foundation
import OPPWAMobile_MSA

enum PaymentMethod: String {
    case blik
    case vipps
    case mobilePay
    case fpx

    var name: String {
        switch self {
        case .blik:
            return "Blik"
        case .vipps:
            return "Vipps"
        case .mobilePay:
            return "MobilePay"
        case .fpx:
            return "FPX"
        }
    }

    var brandName: String {
        switch self {
        case .blik:
            return "BLIK"
        case .vipps:
            return "VIPPS"
        case .mobilePay:
            return "MOBILEPAY"
        case .fpx:
            return "FPX"
                
        }
    }

    var currency: String {
        switch self {
        case .blik:
            return "EUR"
        case .vipps:
            return "NOK"
        case .mobilePay:
            return "DKK"
        case .fpx:
            return "MYR"
        }
    }

    var testMode: String {
        switch self {
        case .blik:
            return Config.internalTestMode
        case .vipps, .mobilePay, .fpx:
            return Config.externalTestMode
        }
    }
}

class AsyncBrandsViewController : RootViewController, SFSafariViewControllerDelegate  {

    let paymentBrands: [PaymentMethod] = [.blik, .vipps, .mobilePay, .fpx]

    @IBOutlet var customBrandsTableView: UITableView!
    @IBOutlet var processingView: UIActivityIndicatorView!
    
    var paymentType: PaymentType = .PA
    var provider: OPPPaymentProvider?
    var safariVC: SFSafariViewController?

    // MARK: - Life cycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "SDK & Async Brands"

        self.provider = OPPPaymentProvider.init(mode: .test)
        processingView.isHidden = true
    }

    // MARK: - Action methods
    @IBAction func paymentTypeChanged(_ sender: UISegmentedControl) {
        paymentType = (sender.selectedSegmentIndex == 0) ? .PA : .DB
    }
    
    private func proceed(for paymentMethod: PaymentMethod) {
        self.showHideProcessingView(isHide: false)
        Request.requestCheckoutID(amount: Config.amount,
                                  currency: paymentMethod.currency,
                                  paymentType: paymentType,
                                  testMode: paymentMethod.testMode) { (checkoutID) in
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }
                guard let checkoutID = checkoutID else {
                    self.showHideProcessingView(isHide: true)
                    Utils.showResult(presenter: self, message: "Checkout ID is empty")
                    return
                }

                guard let transaction = self.createTransaction(checkoutID: checkoutID,
                                                               paymentMethod: paymentMethod) else {
                    self.showHideProcessingView(isHide: true)
                    return
                }
                
                if paymentMethod == .fpx {
                    presentFPXView(transaction)
                } else {
                    submitTranscation(transaction)
                }
            }
        }
    }
    
    func presentFPXView(_ oldTransaction: OPPTransaction) {
        let viewController = FPXBankListController(oldTransaction) {[weak self] (transaction, viewController) in
            viewController.dismiss(animated: true) {
                if let transaction = transaction {
                    self?.submitTranscation(transaction)
                }
            }
        }
        self.present(viewController, animated: true)
    }

    func submitTranscation(_ transaction: OPPTransaction) {
        self.provider!.submitTransaction(transaction, completionHandler: { (transaction, error) in
            DispatchQueue.main.async {
                self.showHideProcessingView(isHide: true)
                if let redirectURL = transaction.redirectURL {
                    self.presenterURL(url: redirectURL)
                }
                self.handleTransactionSubmission(transaction: transaction, error: error)
            }
        })
    }
    
    // MARK: - Payment helpers

    func createTransaction(checkoutID: String, paymentMethod: PaymentMethod) -> OPPTransaction? {
        do {
            let params: OPPPaymentParams? = try getBrandParams(paymentMethod: paymentMethod,
                                                               checkoutID: checkoutID)
            guard let params else {
                return nil
            }
            return OPPTransaction.init(paymentParams: params)
        } catch let error as NSError {
            Utils.showResult(presenter: self, message: error.localizedDescription)
            return nil
        }
    }

    private func getBrandParams(paymentMethod: PaymentMethod,
                                checkoutID: String) throws -> OPPPaymentParams? {
        var params: OPPPaymentParams?
        switch paymentMethod {
        case .blik:
            params = try OPPBlikPaymentParams(checkoutID: checkoutID, otp: "")
            case .vipps, .mobilePay, .fpx:
            params = try OPPPaymentParams(checkoutID: checkoutID, paymentBrand: paymentMethod.brandName)
        }
        guard let params else {
            return nil
        }
        params.shopperResultURL = Config.urlScheme + "://payment"
        return params
    }

    private func showHideProcessingView(isHide: Bool) {
        self.processingView.isHidden = isHide
        if isHide {
            self.processingView.stopAnimating()
        } else {
            self.processingView.startAnimating()
        }
    }

    func presenterURL(url: URL) {
        self.safariVC = SFSafariViewController(url: url)
        self.safariVC?.delegate = self;
        self.present(safariVC!, animated: true, completion: nil)
    }

    override func requestPaymentStatus() {
        // You can either hard-code resourcePath or request checkout info to get the value from the server
        // * Hard-coding: "/v1/checkouts/" + checkoutID + "/payment"
        // * Requesting checkout info:

        guard let checkoutID = self.transaction?.paymentParams.checkoutID else {
            Utils.showResult(presenter: self, message: "Checkout ID is invalid")
            return
        }
        self.transaction = nil

        self.showHideProcessingView(isHide: false)
        self.provider!.requestCheckoutInfo(withCheckoutID: checkoutID) { (checkoutInfo, error) in
            DispatchQueue.main.async {
                guard let resourcePath = checkoutInfo?.resourcePath else {
                    self.processingView.stopAnimating()
                    Utils.showResult(presenter: self, message: "Checkout info is empty or doesn't contain resource path")
                    return
                }

                Request.requestPaymentStatus(resourcePath: resourcePath) { (paymentStatusResponse, error) in
                    DispatchQueue.main.async {
                        self.processingView.stopAnimating()
                        var message = ""
                        if OPPMerchantServer.isSuccessful(response: paymentStatusResponse) || OPPMerchantServer.isPending(response: paymentStatusResponse) {
                            message = (paymentStatusResponse?.resultCode ?? "") + (paymentStatusResponse?.resultDescription ?? "")
                        } else {
                            if (error != nil) {
                                message = error!.localizedDescription
                            } else if let resultCode = paymentStatusResponse?.resultCode,
                                        let resultDescription = paymentStatusResponse?.resultDescription {
                                message = resultCode + " " + resultDescription
                            } else {
                                message = ""
                            }
                        }

                        if ((paymentStatusResponse?.resultDetailsCardholderInfo) != nil  && (paymentStatusResponse?.resultDetailsCardholderInfo.count)! > 0) {
                            message = message + "\n3ds2 transaction returned cardHolderInfo:" + paymentStatusResponse!.resultDetailsCardholderInfo
                        }
                        Utils.showResult(presenter: self, message: message)
                    }
                }
            }
        }
    }

    // MARK: - Safari Delegate

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true) {
            DispatchQueue.main.async {
                self.requestPaymentStatus()
            }
        }
    }
}

extension AsyncBrandsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paymentBrands.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = customBrandsTableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath)
        cell.textLabel?.text = paymentBrands[indexPath.row].name
        return cell
    }
}

extension AsyncBrandsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        proceed(for: paymentBrands[indexPath.row])
    }
}
