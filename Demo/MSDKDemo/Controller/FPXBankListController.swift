//
//  FPXBankListController.swift
//  MSDKDemo
//
//  Created by Dalvi, Vikas on 15/09/25.
//  Copyright © 2025 ACI. All rights reserved.
//

import UIKit

class FPXBankListController: UITableViewController {

    let transaction: OPPTransaction
    let completionHandler: (OPPTransaction?, UIViewController) -> Void
    let banks: [String: String] = OPPPaymentProvider.getFPXBanks()
    lazy var bankList: [String] = {
        return banks.keys.sorted()
    }()
    
    init(_ transaction: OPPTransaction,
         completionHandler: @escaping (OPPTransaction?, UIViewController) -> Void) {
        self.transaction = transaction
        self.completionHandler = completionHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bankList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        cell?.textLabel?.text = bankList[indexPath.row]
        return cell!
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        guard let bankName = banks[bankList[indexPath.row]] else {
            completionHandler(nil, self)
            return
        }
        guard let paymentParams = try? OPPBankAccountPaymentParams.fpxPaymentParams(checkoutID: transaction.paymentParams.checkoutID,
                                                                                    bankName: bankName) else {
            completionHandler(nil, self)
            return
        }
        paymentParams.shopperResultURL = Config.urlScheme + "://payment"
        let transaction = OPPTransaction(paymentParams: paymentParams)
        completionHandler(transaction, self)
    }
}
