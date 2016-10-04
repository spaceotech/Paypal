//
//  ViewController.swift
//  SOPaypal
//
//  Created by Hitesh on 10/4/16.
//  Copyright © 2016 myCompany. All rights reserved.
//

import UIKit
import Pods_SOPaypal

class ViewController: UIViewController, PayPalPaymentDelegate {

    @IBOutlet weak var tblShopping: UITableView!
    var quotesArray : NSMutableArray = [
        ["Product": "Shirt", "Price": "200", "Note": "Nice Shirt"],
        ["Product": "Shoes", "Price": "120", "Note": "Nice Shoes"],
    ]
    
    var payPalConfig = PayPalConfiguration()
    let items:NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    

    //MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quotesArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        configureCell(cell, forRowAtIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, forRowAtIndexPath: NSIndexPath) {
        let lblProduct : UILabel = cell.contentView.viewWithTag(1) as! UILabel
        let lblPrice : UILabel = cell.contentView.viewWithTag(2) as! UILabel
        let lblNote : UILabel = cell.contentView.viewWithTag(3) as! UILabel
        
        let dict : NSDictionary = quotesArray.objectAtIndex(forRowAtIndexPath.row) as! NSDictionary
        lblProduct.text = dict.valueForKey("Product") as? String
        lblPrice.text = "$" + (dict.valueForKey("Price") as! String)
        lblNote.text = dict.valueForKey("Note") as? String
    }
    
    //MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let dict : NSDictionary = quotesArray.objectAtIndex(indexPath.row) as! NSDictionary
        
        self.configurePaypal("Space-0")
        
        self.setItems(dict.valueForKey("Product") as? String, noOfItem: "1", strPrice: dict.valueForKey("Price") as? String, strCurrency: "USD", strSku: nil)
        
        self.goforPayNow(nil, taxPrice: nil, totalAmount: nil, strShortDesc: "Paypal", strCurrency: "USD")
    }
    
    
    func setItems(strItemName:String?, noOfItem:String?, strPrice:String?, strCurrency:String?, strSku:String?) {
        let quantity : UInt = UInt(noOfItem!)!
        
        let item = PayPalItem.init(name: strItemName!, withQuantity: quantity, withPrice: NSDecimalNumber(string: strPrice), withCurrency: strCurrency!, withSku: strSku)
        items.addObject(item)
        print("\(items)")
    }
    
    
    //MARK: Paypal
    func acceptCreditCards() -> Bool {
        return self.payPalConfig.acceptCreditCards
    }
    
    func setAcceptCreditCards(acceptCreditCards: Bool) {
        self.payPalConfig.acceptCreditCards = self.acceptCreditCards()
    }
    
    var environment:String = PayPalEnvironmentNoNetwork {
        willSet(newEnvironment) {
            if (newEnvironment != environment) {
                PayPalMobile.preconnectWithEnvironment(newEnvironment)
            }
        }
    }
    
    //MARK: Configure paypal 
    func configurePaypal(strMarchantName:String) {
        if items.count>0 {
            items.removeAllObjects()
        }
        // Set up payPalConfig
        payPalConfig.acceptCreditCards = self.acceptCreditCards();
        payPalConfig.merchantName = strMarchantName
        payPalConfig.merchantPrivacyPolicyURL = NSURL(string: "https://www.paypal.com/webapps/mpp/ua/privacy-full")
        payPalConfig.merchantUserAgreementURL = NSURL(string: "https://www.paypal.com/webapps/mpp/ua/useragreement-full")
        
        payPalConfig.languageOrLocale = NSLocale.preferredLanguages()[0]
        
        payPalConfig.payPalShippingAddressOption = .PayPal;
        
        print("PayPal iOS SDK Version: \(PayPalMobile.libraryVersion())")
        PayPalMobile.preconnectWithEnvironment(environment)
    }
    
    //MARK: Start Payment
    func goforPayNow(shipPrice:String?, taxPrice:String?, totalAmount:String?, strShortDesc:String?, strCurrency:String?) {
        var subtotal : NSDecimalNumber = 0
        var shipping : NSDecimalNumber = 0
        var tax : NSDecimalNumber = 0
        if items.count > 0 {
            subtotal = PayPalItem.totalPriceForItems(items as [AnyObject])
        } else {
            subtotal = NSDecimalNumber(string: totalAmount)
        }
        
        // Optional: include payment details
        if (shipPrice != nil) {
            shipping = NSDecimalNumber(string: shipPrice)
        }
        if (taxPrice != nil) {
            tax = NSDecimalNumber(string: taxPrice)
        }
        
        var description = strShortDesc
        if (description == nil) {
            description = ""
        }
        
        let paymentDetails = PayPalPaymentDetails(subtotal: subtotal, withShipping: shipping, withTax: tax)
        
        let total = subtotal.decimalNumberByAdding(shipping).decimalNumberByAdding(tax)
        
        let payment = PayPalPayment(amount: total, currencyCode: strCurrency!, shortDescription: description!, intent: .Sale)
        
        payment.items = items as [AnyObject]
        payment.paymentDetails = paymentDetails
        
        self.payPalConfig.acceptCreditCards = self.acceptCreditCards();
        
        if self.payPalConfig.acceptCreditCards == true {
            print("We are able to do the card payment")
        }
        
        if (payment.processable) {
            let objVC = PayPalPaymentViewController(payment: payment, configuration: payPalConfig, delegate: self)
            
            self.presentViewController(objVC!, animated: true, completion: { () -> Void in
                print("Paypal Presented")
            })
        }
        else {
            print("Payment not processalbe: \(payment)")
        }
    }
    
    
    //MARK: PayPalPayment Delegate
    func payPalPaymentDidCancel(paymentViewController: PayPalPaymentViewController) {
        paymentViewController.dismissViewControllerAnimated(true) { () -> Void in
            print("and Dismissed")
        }
        print("Payment cancel")
    }
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController, didCompletePayment completedPayment: PayPalPayment) {
        paymentViewController.dismissViewControllerAnimated(true) { () -> Void in
            print("and done")
            let alert = UIAlertController(title: "SOPaypal", message: "Payment done successfully.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        print("Paymane is going on")
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

