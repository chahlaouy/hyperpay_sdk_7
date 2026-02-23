//
//
// Copyright (c) $$year$$ by ACI Worldwide, Inc.
// © Copyright ACI Worldwide, Inc. 2018,2023
// All rights reserved.
//
// This software is the confidential and proprietary information
// of ACI Worldwide Inc ("Confidential Information"). You shall
// not disclose such Confidential Information and shall use it
// only in accordance with the terms of the license agreement
// you entered with ACI Worldwide Inc.
//
        

import Foundation
import OPPWAMobile
import UIKit

class CardViewController: UIViewController, OPPCardDetailsDataSource {
    
    var cardControllerDelegate: OPPCardControllerDelegate? = nil
    var validationError: String? = nil
    
    @IBOutlet weak var cardNumberField: UITextField!
    @IBOutlet weak var cardHolderField: UITextField!
    @IBOutlet weak var expiryDateFiled: UITextField!
    @IBOutlet weak var cvvField: UITextField!
    @IBOutlet weak var brandLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardControllerDelegate?.viewControllerDidLoaded()
        cardNumberField.placeholder = "Card Number"
        cardHolderField.placeholder = "Card Holder"
        expiryDateFiled.placeholder = "Expiry Date"
        cvvField.placeholder = "CVV"
        if let paymentBrand = cardControllerDelegate?.paymentBrand() {
            brandLabel.text = "Payment Brand: "  + paymentBrand
        }
    }
    
    @IBAction func payAction(_ sender: Any) {
        validationError = nil;
        cardControllerDelegate?.submitPaymentTransaction(completionHandler: { result in
            if (result) {
                print("Transaction successfully submitted")
            } else {
                print("Transaction submit failed")
            }
        })
    }
    
    //required protocol methods
    func cardControllerCardNumberTextField() -> UITextField {
        return cardNumberField
    }
    
    func cardControllerCardHolderTextField() -> UITextField {
        return cardHolderField
    }
    
    func cardControllerExpirationDateTextField() -> UITextField {
        return expiryDateFiled
    }
    
    func cardControllerCVVTextField() -> UITextField {
        return cvvField
    }
    
    
    //optional protocol methods
    func cardControllerTextField(_ textField: UITextField, errorDidHappen error: Error?) {
        if let error = error {
            let errorString  = error.localizedDescription
            print(errorString)
            validationError = errorString;
        } else {
            validationError = nil;
        }
        
        if let validationError = validationError {
            errorLabel.text = validationError;
        }
    }
    
    
    func cardController(onPaymentBrandsDetected paymentBrands: [String]?, error: Error?) {
        if let paymentBrands = paymentBrands,
           let paymentBrand = paymentBrands.first {
            print("Detected brands: ", paymentBrands)
            brandLabel.text = "Payment Brand: " + paymentBrand
        }
    }
}
