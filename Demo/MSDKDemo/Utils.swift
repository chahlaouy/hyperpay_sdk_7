import UIKit

class Utils: NSObject {

    static func SDKVersion() -> String? {
        if let OPPClass = NSClassFromString("OPPPaymentProvider") as? OPPPaymentProvider.Type {
            let bundle = Bundle(for: OPPClass)
            if let path = bundle.path(forResource: "Info", ofType: "plist") {
                if let infoDict = NSDictionary(contentsOfFile: path) as? [String: Any] {
                    return infoDict["CFBundleShortVersionString"] as? String
                }
            }
        }
        return ""
    }
    
    static func amountAsString() -> String {
        return String(format: "%.2f", Config.amount) + " " + Config.currency
    }
    
    static func amountAsString(amount: Double, currency: String) -> String {
        return String(format: "%.2f", amount) + " " + currency
    }
    
    static func showResult(presenter: UIViewController, message: String?) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        presenter.present(alert, animated: true, completion: nil)
    }
    
    static func configureCheckoutSettings() -> OPPCheckoutSettings {
        let checkoutSettings = OPPCheckoutSettings.init()
        checkoutSettings.paymentBrands = Config.checkoutPaymentBrands
        checkoutSettings.shopperResultURL = Config.urlScheme + "://payment"
        
        checkoutSettings.theme.navigationBarBackgroundColor = Config.mainColor
        checkoutSettings.theme.confirmationButtonColor = Config.mainColor
        checkoutSettings.theme.accentColor = Config.mainColor
        checkoutSettings.theme.cellHighlightedBackgroundColor = Config.mainColor
        checkoutSettings.theme.sectionBackgroundColor = Config.mainColor.withAlphaComponent(0.05)
        let threeDS2Config = OPPThreeDSConfig.init()
        threeDS2Config.appBundleID = "com.aciworldwide.MSDKDemo"
        checkoutSettings.threeDSConfig = threeDS2Config
               
        let afterpayDict = [ "inlineFlow" : ["'AFTERPAY_PACIFIC'"]]
        let jsConfig = [ "onReady" :  "function(){$(\"button.wpwl-button-brand\").hide();setTimeout(function() { wpwl.executePayment(\"wpwl-container-virtualAccount-AFTERPAY_PACIFIC\"); }, 1500);}" ]
        let afterpayConfig = OPPWpwlOptions.initWithConfiguration(afterpayDict, jsFunctions: jsConfig)
        checkoutSettings.wpwlOptions["AFTERPAY_PACIFIC"] = afterpayConfig
        if (Config.customControllersEnabled) {
            checkoutSettings.customController(OPPViewController.cardDetails, withUiController: CardViewController.init(nibName: "CardViewController", bundle: nil))
        }
        
        return checkoutSettings
    }

}
