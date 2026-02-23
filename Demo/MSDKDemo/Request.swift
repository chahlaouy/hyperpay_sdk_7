import UIKit
import OPPWAMobile_MSA

//TODO: This class uses our test integration server (OPPWAMobile_MSA.xcframework); please adapt it to use your own backend API.
class Request: NSObject {
    
    static func requestCheckoutID(amount: Double,
                                  currency: String,
                                  paymentType: PaymentType = .PA,
                                  testMode: String = "INTERNAL",
                                  completion: @escaping (String?) -> Void) {
        let extraParamaters: [String:String] = [
            "testMode": testMode,
            "sendRegistration": "true"
        ]
        
        OPPMerchantServer.requestCheckoutId(amount: amount,
                                            currency: currency,
                                            paymentType: paymentType.rawValue,
                                            serverMode: .test,
                                            extraParameters: extraParamaters) { checkoutId, error in
            if let checkoutId = checkoutId {
                completion(checkoutId)
            } else {
                completion(nil)
            }
        }
    }
    
    static func requestCheckoutID(amount: Double, currency: String, extraParamaters: [String:String], completion: @escaping (String?) -> Void) {
        OPPMerchantServer.requestCheckoutId(amount: amount,
                                            currency: currency,
                                            paymentType: CopyandPayConfig.paymentType,
                                            serverMode: .test,
                                            extraParameters: extraParamaters) { checkoutId, error in
            if let checkoutId = checkoutId {
                completion(checkoutId)
            } else {
                completion(nil)
            }
        }
    }
    
    static func requestPaymentStatus(resourcePath: String, completion: @escaping (OPPPaymentStatusResponse?, Error?) -> Void) {
        OPPMerchantServer.requestPaymentStatus(resourcePath: resourcePath) { paymentStatusResponse, error in
            completion(paymentStatusResponse, error)
        }
    }
}
