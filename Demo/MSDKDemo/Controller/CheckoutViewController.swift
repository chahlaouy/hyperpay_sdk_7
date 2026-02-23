import UIKit

class CheckoutViewController: RootViewController {
    @IBOutlet var amountLabel: UILabel!
    @IBOutlet var checkoutButton: UIButton!
    @IBOutlet var processingView: UIActivityIndicatorView!
    
    // MARK: - Life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Ready-to-use UI"
        self.amountLabel.text = Utils.amountAsString()
    }
    
    // MARK: - Action methods
    
    @IBAction func checkoutButtonAction(_ sender: UIButton) {
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
                self.checkoutProvider?.delegate = self
                self.checkoutProvider?.presentCheckout(forSubmittingTransactionCompletionHandler: { (transaction, error) in
                    DispatchQueue.main.async {
                        self.handleTransactionSubmission(transaction: transaction, error: error)
                    }
                }, cancelHandler: nil)
            }
        })
    }
}
