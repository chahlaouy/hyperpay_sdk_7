import UIKit
import SafariServices
import OPPWAMobile_MSA

enum CardParamsError: Error {
    case invalidParam(String)
}

class CustomUIViewController: RootViewController, SFSafariViewControllerDelegate, OPPThreeDSEventListener {
    @IBOutlet var holderTextField: UITextField!
    @IBOutlet var numberTextField: UITextField!
    @IBOutlet var expiryMonthTextField: UITextField!
    @IBOutlet var expiryYearTextField: UITextField!
    @IBOutlet var cvvTextField: UITextField!
    @IBOutlet var processingView: UIActivityIndicatorView!
    @IBOutlet var cardBrandLabel: UILabel!
    @IBOutlet weak var useNGeniusSwitch: UISwitch!
    @IBOutlet weak var nGeniusInfoLabel: UILabel!
    
    var provider: OPPPaymentProvider?
    var safariVC: SFSafariViewController?
    
    // MARK: - Life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "SDK & your own UI"
        self.cardBrandLabel.text = Config.cardBrand
        self.holderTextField.text = Config.cardHolder
        self.numberTextField.text = Config.cardNumber
        self.expiryMonthTextField.text = Config.cardExpiryMonth
        self.expiryYearTextField.text = Config.cardExpiryYear
        self.cvvTextField.text = Config.cardCVV
        
        self.provider = OPPPaymentProvider.init(mode: .test)
        self.provider?.threeDSEventListener = self
    }
    
    // MARK: - Action methods
    
    @IBAction func payButtonAction(_ sender: Any) {
        do {
            try self.validateFields()
        } catch CardParamsError.invalidParam(let reason) {
            Utils.showResult(presenter: self, message: reason)
            return
        } catch {
            Utils.showResult(presenter: self, message: "Parameters are invalid")
            return
        }
        
        self.view.endEditing(true)
        self.processingView.startAnimating()
        
        Request.requestCheckoutID(amount: Config.amount,
                                  currency: useNGeniusSwitch.isOn ? Config.nGeniusCurrency : Config.currency,
                                  testMode: useNGeniusSwitch.isOn ? Config.externalTestMode : Config.internalTestMode) { (checkoutID) in
            DispatchQueue.main.async {
                guard let checkoutID = checkoutID else {
                    self.processingView.stopAnimating()
                    Utils.showResult(presenter: self, message: "Checkout ID is empty")
                    return
                }
                
                guard let transaction = self.createTransaction(checkoutID: checkoutID) else {
                    self.processingView.stopAnimating()
                    return
                }
                
                self.provider!.submitTransaction(transaction, completionHandler: { (transaction, error) in
                    DispatchQueue.main.async {
                        self.processingView.stopAnimating()
                        if let redirectURL = transaction.redirectURL {
                            self.presenterURL(url: redirectURL)
                        }
                        self.handleTransactionSubmission(transaction: transaction, error: error)
                    }
                })
            }
        }
    }
    
    @IBAction func useNGeniusValueChanged(_ sender: UISwitch) {
        nGeniusInfoLabel.isHidden = !sender.isOn
        numberTextField.text = sender.isOn ? Config.nGeniusCardNumber : Config.cardNumber
    }
    
    // MARK: - Payment helpers
    
    func createTransaction(checkoutID: String) -> OPPTransaction? {
        do {
            let params = try OPPCardPaymentParams.init(checkoutID: checkoutID,
                                                       paymentBrand: useNGeniusSwitch.isOn ? Config.nGeniusCardBrand :  Config.cardBrand,
                                                       holder: self.holderTextField.text!,
                                                       number: self.numberTextField.text!,
                                                       expiryMonth: self.expiryMonthTextField.text!,
                                                       expiryYear: self.expiryYearTextField.text!,
                                                       cvv: self.cvvTextField.text!)
            params.shopperResultURL = Config.urlScheme + "://payment"
            return OPPTransaction.init(paymentParams: params)
        } catch let error as NSError {
            Utils.showResult(presenter: self, message: error.localizedDescription)
            return nil
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
        
        self.processingView.startAnimating()
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
    
    // MARK: - Fields validation
    
    func validateFields() throws {
        guard let holder = self.holderTextField.text, OPPCardPaymentParams.isHolderValid(holder) else {
            throw CardParamsError.invalidParam("Card holder name is invalid.")
        }
        
        guard let number = self.numberTextField.text, OPPCardPaymentParams.isNumberValid(number, luhnCheck: true) else {
            throw CardParamsError.invalidParam("Card number is invalid.")
        }
        
        guard let month = self.expiryMonthTextField.text, let year = self.expiryYearTextField.text, !OPPCardPaymentParams.isExpired(withExpiryMonth: month, andYear: year) else {
            throw CardParamsError.invalidParam("Expiry date is invalid")
        }
        
        guard let cvv = self.cvvTextField.text, OPPCardPaymentParams.isCvvValid(cvv) else {
            throw CardParamsError.invalidParam("CVV is invalid")
        }
    }
    
    // MARK: - OPPThreeDSEventListener methods
    
    func onThreeDSChallengeRequired(completion: @escaping (UINavigationController) -> Void) {
        completion(self.navigationController!)
    }

    func onThreeDSConfigRequired(completion: @escaping (OPPThreeDSConfig) -> Void) {
        let config = OPPThreeDSConfig()
        config.appBundleID = "com.aciworldwide.MSDKDemo"
        config.isBrowserDataRequired = useNGeniusSwitch.isOn
        completion(config)
    }
    
    // MARK: - Safari Delegate
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true) {
            DispatchQueue.main.async {
                self.requestPaymentStatus()
            }
        }
    }
    
    // MARK: - Keyboard dismissing on tap
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
