import UIKit

class CopyandPayViewController: RootViewController {
    
    @IBOutlet var amountLabel: UILabel!
    @IBOutlet var checkoutButton: UIButton!
    @IBOutlet var processingView: UIActivityIndicatorView!
    
    // MARK: - Life cycle methods    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "COPYandPAY"
        self.amountLabel.text = Utils.amountAsString(amount: CopyandPayConfig.amount, currency: CopyandPayConfig.currency)
    }
    
    // MARK: - Action methods
    @IBAction  func buttonAction(_ sender: UIButton) {
        self.processingView.startAnimating()
        sender.isEnabled = false
        var extraParamaters: [String:String] = [
            "testMode": "EXTERNAL",
            "sendRegistration": "false"
        ]
        
        for key in CopyandPayConfig.afterpayParams.keys {
            extraParamaters[key] = CopyandPayConfig.afterpayParams[key]
        }
        
        Request.requestCheckoutID(amount: CopyandPayConfig.amount, currency: CopyandPayConfig.currency, extraParamaters: extraParamaters, completion: {(checkoutID) in
            DispatchQueue.main.async {
                self.processingView.stopAnimating()
                sender.isEnabled = true
                
                guard let checkoutID = checkoutID else {
                    Utils.showResult(presenter: self, message: "Checkout ID is empty")
                    return
                }
                self.checkoutProvider = self.configureCheckoutProvider(checkoutID: checkoutID)
                self.checkoutProvider?.delegate = self
                self.checkoutProvider?.presentCheckout(forSubmittingTransactionCompletionHandler: { (transaction, error) in
                    DispatchQueue.main.async {
                        self.handleTransactionSubmission(transaction: transaction, error: error)
                    }
                }, cancelHandler: nil)
            }
        })
    }
    
    // MARK: - Payment helpers
    override func configureCheckoutProvider(checkoutID: String) -> OPPCheckoutProvider? {
        let provider = OPPPaymentProvider.init(mode: .test)
        let checkoutSettings = Utils.configureCheckoutSettings()
        checkoutSettings.storePaymentDetails = .prompt
        checkoutSettings.paymentBrands = CopyandPayConfig.checkoutPaymentBrands
        return OPPCheckoutProvider.init(paymentProvider: provider, checkoutID: checkoutID, settings: checkoutSettings)
    }
}

