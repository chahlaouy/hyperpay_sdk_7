import UIKit

class PaymentButtonViewController: RootViewController {
    @IBOutlet var paymentButton: OPPPaymentButton!
    @IBOutlet var amountLabel: UILabel!
    @IBOutlet var processingView: UIActivityIndicatorView!
    
    // MARK: - Life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Payment button"
        self.amountLabel.text = Utils.amountAsString()
        self.paymentButton.paymentBrand = Config.paymentButtonBrand
        self.paymentButton.imageView?.image = self.paymentButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
    }
    
    // MARK: - Action methods

    @IBAction func paymentButtonAction(_ sender: OPPPaymentButton) {
        self.processingView.startAnimating()
        sender.isEnabled = false
        Request.requestCheckoutID(amount: Config.amount, currency: Config.currency, completion: {(checkoutID) in
            DispatchQueue.main.async {
                self.processingView.stopAnimating()
                sender.isEnabled = true
                
                guard let checkoutID = checkoutID else {
                    Utils.showResult(presenter: self, message: "Checkout ID is empty")
                    return
                }
                
                self.checkoutProvider = self.configureCheckoutProvider(checkoutID: checkoutID)
                self.checkoutProvider?.presentCheckout(withPaymentBrand: sender.paymentBrand, loadingHandler: { (inProgress) in
                    self.loadingHandler(inProgress: inProgress)
                }, completionHandler: { (transaction, error) in
                    DispatchQueue.main.async {
                        self.handleTransactionSubmission(transaction: transaction, error: error)
                    }
                }, cancelHandler: nil)
            }
        })
    }
    
    // MARK: - Payment helpers
    func loadingHandler(inProgress: Bool) {
        if inProgress {
            self.processingView.startAnimating()
        } else {
            self.processingView.stopAnimating()
        }
    }
}
