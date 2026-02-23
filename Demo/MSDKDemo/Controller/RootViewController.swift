import UIKit
import OPPWAMobile_MSA

class RootViewController: UIViewController, OPPCheckoutProviderDelegate {
    var checkoutProvider: OPPCheckoutProvider?
    var transaction: OPPTransaction?
    
    // MARK: - Life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - OPPCheckoutProviderDelegate methods
    
    // This method is called right before submitting a transaction to the Server.
    func checkoutProvider(_ checkoutProvider: OPPCheckoutProvider, continueSubmitting transaction: OPPTransaction, completion: @escaping (String?, Bool) -> Void) {
        // To continue submitting you should call completion block which expects 2 parameters:
        // checkoutID - you can create new checkoutID here or pass current one
        // abort - you can abort transaction here by passing 'true'
        completion(transaction.paymentParams.checkoutID, false)
    }
    
    // MARK: - Payment helpers
    
    func handleTransactionSubmission(transaction: OPPTransaction?, error: Error?) {
        guard let transaction = transaction else {
            Utils.showResult(presenter: self, message: error?.localizedDescription)
            return
        }
        
        self.transaction = transaction
        if transaction.type == .synchronous {
            // If a transaction is synchronous, just request the payment status
            self.requestPaymentStatus()
        } else if transaction.type == .asynchronous {
            // If a transaction is asynchronous, SDK opens transaction.redirectUrl in a browser
            // Subscribe to notifications to request the payment status when a shopper comes back to the app
            NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveAsynchronousPaymentCallback), name: Notification.Name(rawValue: Config.asyncPaymentCompletedNotificationKey), object: nil)
        } else {
            Utils.showResult(presenter: self, message: "Invalid transaction")
        }
    }
    
    func configureCheckoutProvider(checkoutID: String) -> OPPCheckoutProvider? {
        let provider = OPPPaymentProvider.init(mode: .test)
        let checkoutSettings = Utils.configureCheckoutSettings()
        checkoutSettings.storePaymentDetails = .prompt
        return OPPCheckoutProvider.init(paymentProvider: provider, checkoutID: checkoutID, settings: checkoutSettings)
    }
    
    func requestPaymentStatus() {
        guard let resourcePath = self.transaction?.resourcePath else {
            Utils.showResult(presenter: self, message: "Resource path is invalid")
            return
        }
        
        self.transaction = nil
        Request.requestPaymentStatus(resourcePath: resourcePath) { (paymentStatusResponse, error) in
            DispatchQueue.main.async {
                var message = ""
                if OPPMerchantServer.isSuccessful(response: paymentStatusResponse) || OPPMerchantServer.isPending(response: paymentStatusResponse) {
                    message = (paymentStatusResponse?.resultCode ?? "") + (paymentStatusResponse?.resultDescription ?? "")
                } else {
                    if (error != nil) {
                        message = error!.localizedDescription
                    } else {
                        message = paymentStatusResponse!.resultCode + " " + paymentStatusResponse!.resultDescription
                    }
                }
                if ((paymentStatusResponse?.resultDetailsCardholderInfo) != nil && (paymentStatusResponse?.resultDetailsCardholderInfo.count)! > 0) {
                    message = message + "\n3ds2 transaction returned cardHolderInfo:" + paymentStatusResponse!.resultDetailsCardholderInfo
                }
                Utils.showResult(presenter: self, message: message)
            }
        }
    }
    
    // MARK: - Async payment callback
    
    @objc func didReceiveAsynchronousPaymentCallback() {
        if let topViewController = OPPUIUtil.findTopViewController() as? SFSafariViewController {
            topViewController.dismiss(animated: false)
        }
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: Config.asyncPaymentCompletedNotificationKey), object: nil)
        if let checkoutProvider {
            checkoutProvider.dismissCheckout(animated: true) {
                DispatchQueue.main.async {
                    self.requestPaymentStatus()
                }
            }
        } else {
            DispatchQueue.main.async {
                self.requestPaymentStatus()
            }
        }
    }
}
