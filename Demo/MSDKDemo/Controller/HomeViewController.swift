import UIKit

class HomeViewController: UIViewController {
    @IBOutlet var versionLabel: UILabel!
    
    // MARK: - Life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let version = Utils.SDKVersion() {
            self.versionLabel.text = "mobile SDK v" + version
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Config.customControllersEnabled = false;
    }
    
    @IBAction func readyToUseUiWithCustomVcTarget(_ sender: Any) {
        Config.customControllersEnabled = true;
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let checkoutViewController = storyboard.instantiateViewController(withIdentifier: "CheckoutViewController") as! CheckoutViewController
        self.navigationController?.pushViewController(checkoutViewController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
