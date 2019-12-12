//
//  ZebraPrintManager.swift
//  ZebraLabelPrinterSwift
//
//  Created by Sachin Pampannavar on 11/26/19.
//  Copyright © 2019 Goalsr. All rights reserved.
//

import ExternalAccessory
import CoreBluetooth
import MobileCoreServices
import UIKit

protocol EAAccessoryManagerConnectionStatusDelegate {
    func changeLabelStatus() -> Void
    func didPrintSuccessfully()
    func didFailedToPrint()
}

enum CommonPrintingFormat: String {
    case start = "! 0 200 200 150 1"
    case end = "\nFORM\nPRINT "
}

enum PrinterLanguage: String {
    case ZPL
    case CPCL
}

enum LabelSize: String {
    case TwoByOne
    case ThreeByTwo
    case FourByTwo
    case FourByThree
    case FourBySix
}

class ZebraPrintManager: NSObject {
    
    var manager: EAAccessoryManager!
    var isConnected: Bool = false
    var connectionDelegate: EAAccessoryManagerConnectionStatusDelegate?
    private var printerConnection: MfiBtPrinterConnection?
    private var serialNumber: String?
    private var disconnectNotificationObserver: NSObjectProtocol?
    private var connectedNotificationObserver: NSObjectProtocol?
    static let sharedInstance = ZebraPrintManager()
    
    private override init() {
        super.init()
        manager = EAAccessoryManager.shared()
        self.findConnectedPrinter { [weak self] bool in
            if let strongSelf = self {
                strongSelf.isConnected = bool
            }
        }
        //Notifications
        disconnectNotificationObserver = NotificationCenter.default.addObserver(forName: Notification.Name.EAAccessoryDidDisconnect, object: nil, queue: nil, using: didDisconnect)
        
        connectedNotificationObserver = NotificationCenter.default.addObserver(forName: Notification.Name.EAAccessoryDidConnect, object: nil, queue: nil, using: didConnect)
        manager.registerForLocalNotifications()
        
    }
    
    deinit {
        if let disconnectNotificationObserver = disconnectNotificationObserver {
            NotificationCenter.default.removeObserver(disconnectNotificationObserver)
        }
        if let connectedNotificationObserver = connectedNotificationObserver {
            NotificationCenter.default.removeObserver(connectedNotificationObserver)
        }
    }
    
    func findConnectedPrinter(completion: (Bool) -> Void) {
        let connectedDevices = manager.connectedAccessories
        for device in connectedDevices {
            if device.protocolStrings.contains("com.zebra.rawport") {
                serialNumber = device.serialNumber
                connectToPrinter(completion: { completed in
                    completion(completed)
                })
            }
        }
    }
    
    private func connectToPrinter( completion: (Bool) -> Void) {
        printerConnection = MfiBtPrinterConnection(serialNumber: serialNumber)
        
        let isConnectionOpen = printerConnection?.open() ?? false
        if isConnectionOpen {
            completion(true)
        } else {
            completion(false)
        }
    }
    
    func closeConnectionToPrinter() {
        printerConnection?.close()
    }
    
    
    
    private func writeToPrinter(with data: Data) {
        print(String(data: data, encoding: String.Encoding.utf8) ?? "")
        
        connectToPrinter { (isConnectionOpen) in
            if isConnectionOpen {
                var error:NSError?
                printerConnection?.write(data, error: &error)
                if error != nil {
                    print("Error executing data writing \(String(describing: error))")
                    self.connectionDelegate?.didFailedToPrint()
                    return
                } else {
                    self.connectionDelegate?.didPrintSuccessfully()
                }
                
            } else {
                print("connection is not open")
            }
        }
    }
    
    
    private func didDisconnect(notification: Notification) {
        isConnected = false
        connectionDelegate?.changeLabelStatus()
    }
    
    private func didConnect(notification: Notification) {
        isConnected = true
        connectionDelegate?.changeLabelStatus()
    }
    
    private func checkPrinterConnection(completion: (String?) -> Void) {
        if self.printerConnection == nil {
            connectToPrinter { (isConnected) in
                if isConnected {
                    guard let language = getPrinterLanguage() else {
                        completion(nil)
                        return
                    }
                    completion(language)
                } else {
                    print("Printer Connection is not open")
                    self.connectionDelegate?.didFailedToPrint()
                }
            }
        } else {
            guard let language = getPrinterLanguage() else {
                completion(nil)
                return
            }
            completion(language)
        }
        
    }
    
    private func getPrinterLanguage() -> String? {
        do {
            let printer = try ZebraPrinterFactory.getInstance(self.printerConnection)
            let language = printer.getControlLanguage()
            if language == PRINTER_LANGUAGE_ZPL {
                return PrinterLanguage.ZPL.rawValue
            } else {
                return PrinterLanguage.CPCL.rawValue
            }
        } catch let err{
            print(err.localizedDescription)
            return nil
        }
    }
    
    func printLabelAndBarcode(product: [String: Any], numberOfPrints: Int, labelSize: LabelSize) {
        
        checkPrinterConnection { (printerLanguage) in
            if printerLanguage != nil {
            if  printerLanguage == PrinterLanguage.ZPL.rawValue {
                switch labelSize {
                case LabelSize.TwoByOne:
                    printLabelZPLTwoByOne(product: product, numberOfPrints: numberOfPrints)
                case LabelSize.ThreeByTwo:
                    print("3 x 2")
                    printLabelZPLThreeByTwo(product: product, numberOfPrints: numberOfPrints)
                case LabelSize.FourByTwo:
                    print("4 x 2")
                case LabelSize.FourByThree:
                    print("4 x 3")
                case LabelSize.FourBySix:
                    print("4 x 6")
                }
                
            } else {
                let min = "MIN:-6"
                let max = "MAX: 100"
                
                switch labelSize {
                case LabelSize.TwoByOne:
                    printLabelCPCLTwoByOne(with: product, min: min, max: max)
                case LabelSize.ThreeByTwo:
                    print("3 x 2")
                    printLabelCPCLThreeByTwo(with: product, min: min, max: max)
                case LabelSize.FourByTwo:
                    print("4 x 2")
                case LabelSize.FourByThree:
                    print("4 x 3")
                case LabelSize.FourBySix:
                    print("4 x 6")
                }
            }
            } else {
                self.connectionDelegate?.didFailedToPrint()
                print("Failed get printer language")
            }
        }
        
    }
    
}

//ZPL
extension ZebraPrintManager {
    
    private func printLabelZPLTwoByOne(product: [String: Any], numberOfPrints: Int) {
        
        /*
         This routine is provided to you as an example of how to create a variable length label with user specified data.
         The basic flow of the example is as follows
         
         Header of the label with some variable data
         Body of the label
         Loops thru user content and creates small line items of printed material
         Footer of the label
         
         As you can see, there are some variables that the user provides in the header, body and footer, and this routine uses that to build up a proper ZPL string for printing.
         Using this same concept, you can create one label for your receipt header, one for the body and one for the footer. The body receipt will be duplicated as many items as there are in your variable data
         
         */
        
        /*
         Some basics of ZPL. Find more information here : http://www.zebra.com/content/dam/zebra/manuals/en-us/printer/zplii-pm-vol2-en.pdf
         
         ^XA indicates the beginning of a label
         ^PW sets the width of the label (in dots)
         ^MNN sets the printer in continuous mode (variable length receipts only make sense with variably sized labels)
         ^LL sets the length of the label (we calculate this value at the end of the routine)
         ^LH sets the reference axis for printing.
         You will notice we change this positioning of the 'Y' axis (length) as we build up the label. Once the positioning is changed, all new fields drawn on the label are rendered as if '0' is the new home position
         ^FO sets the origin of the field relative to Label Home ^LH
         ^A sets font information
         ^FD is a field description
         ^GB is graphic boxes (or lines)
         ^B sets barcode information
         ^XZ indicates the end of a label
         */
        
        let productBarcode = product["productBarcode"] as? String ?? ""
        let productType = product["productType"] as? String ?? ""
        let productName = product["productName"] as? String ?? ""
        let productWeigh = product["productWeigh"] as? String ?? ""
        let productPrice = product["productPrice"] as? String ?? ""
        
        var productFirstLine = ""
        var productSecondLine = ""
        var isTwoLineProductName = false
        if productName.count > 14 {
            productFirstLine = String(productName.prefix(14))
            productSecondLine = String(productName.suffix(productName.count - 14))
            isTwoLineProductName = true
        }
        
        var testLabel = ""
        
        let start = "^XA"
        let printQuantity = "^PQ\(numberOfPrints)"
        let end = "^XZ"
        
        let barcode1 = "^FO230,100^BY1"
        let barcode2 = "^B3N,N,80,Y,N"
        let barcode3 = "^ADN,20,10^FD\(productBarcode)^FS"
        
        if !isTwoLineProductName {
            let productLine1 = "^FO230,200^ADN,20,10^FD(\(productType)) \(productName)^FS"
            let productLine2 = "^FO230,230^ADN,20,10^FD\(productPrice) (\(productWeigh))^FS"
            testLabel.append(start)
            testLabel.append(barcode1)
            testLabel.append(barcode2)
            testLabel.append(barcode3)
            testLabel.append(productLine1)
            testLabel.append(productLine2)
            testLabel.append(printQuantity)
            testLabel.append(end)
            
        } else {
            
            let productLine1 = "^FO230,200^ADN,20,10^FD(\(productType)) \(productFirstLine)^FS"
            let productLine2 = "^FO230,230^ADN,20,10^FD\(productSecondLine)^FS"
            let productLine3 = "^FO230,260^ADN,20,10^FD\(productPrice) (\(productWeigh))^FS"
            testLabel.append(start)
            testLabel.append(barcode1)
            testLabel.append(barcode2)
            testLabel.append(barcode3)
            testLabel.append(productLine1)
            testLabel.append(productLine2)
            testLabel.append(productLine3)
            testLabel.append(printQuantity)
            testLabel.append(end)
            
        }
        
        //for iphones the end commnd is being stripped out, so we are appending againg the end command
        if UIDevice.current.userInterfaceIdiom == .phone {
            testLabel.append(end)
        }
        
        if let unsafePtr = testLabel.toPointer() {
            let data = Data(bytes: unsafePtr, count: testLabel.count)
            writeToPrinter(with: data)
        }
        
    }
    
    private func printLabelZPLThreeByTwo(product: [String: Any], numberOfPrints: Int) {
        
        /*
         This routine is provided to you as an example of how to create a variable length label with user specified data.
         The basic flow of the example is as follows
         
         Header of the label with some variable data
         Body of the label
         Loops thru user content and creates small line items of printed material
         Footer of the label
         
         As you can see, there are some variables that the user provides in the header, body and footer, and this routine uses that to build up a proper ZPL string for printing.
         Using this same concept, you can create one label for your receipt header, one for the body and one for the footer. The body receipt will be duplicated as many items as there are in your variable data
         
         */
        
        /*
         Some basics of ZPL. Find more information here : http://www.zebra.com/content/dam/zebra/manuals/en-us/printer/zplii-pm-vol2-en.pdf
         
         ^XA indicates the beginning of a label
         ^PW sets the width of the label (in dots)
         ^MNN sets the printer in continuous mode (variable length receipts only make sense with variably sized labels)
         ^LL sets the length of the label (we calculate this value at the end of the routine)
         ^LH sets the reference axis for printing.
         You will notice we change this positioning of the 'Y' axis (length) as we build up the label. Once the positioning is changed, all new fields drawn on the label are rendered as if '0' is the new home position
         ^FO sets the origin of the field relative to Label Home ^LH
         ^A sets font information
         ^FD is a field description
         ^GB is graphic boxes (or lines)
         ^B sets barcode information
         ^XZ indicates the end of a label
         */
        
        let productBarcode = product["productBarcode"] as? String ?? ""
        let productType = product["productType"] as? String ?? ""
        let productName = product["productName"] as? String ?? ""
        let productWeigh = product["productWeigh"] as? String ?? ""
        let productPrice = product["productPrice"] as? String ?? ""
        
        var productFirstLine = ""
        var productSecondLine = ""
        var isTwoLineProductName = false
        if productName.count > 9 {
            productFirstLine = String(productName.prefix(9))
            productSecondLine = String(productName.suffix(productName.count - 9))
            isTwoLineProductName = true
        }
        
        var testLabel = ""
        
        let start = "^XA"
        let printQuantity = "^PQ\(numberOfPrints)"
        let end = "^XZ"
        
        let barcode1 = "^FO150,50^BY1"
        let barcode2 = "^B3N,N,80,Y,N"
        let barcode3 = "^ADN,20,10^FD\(productBarcode)^FS"
        
        if !isTwoLineProductName {
            let productLine1 = "^FO150,150^ADN,20,10^FD(\(productType)) \(productName)^FS"
            let productLine2 = "^FO150,165^ADN,20,10^FD\(productPrice) (\(productWeigh))^FS"
            testLabel.append(start)
            testLabel.append(barcode1)
            testLabel.append(barcode2)
            testLabel.append(barcode3)
            testLabel.append(productLine1)
            testLabel.append(productLine2)
            testLabel.append(printQuantity)
            testLabel.append(end)
            
        } else {
            
            let productLine1 = "^FO150,150^ADN,20,10^FD(\(productType)) \(productFirstLine)^FS"
            let productLine2 = "^FO150,165^ADN,20,10^FD\(productSecondLine)^FS"
            let productLine3 = "^FO150,180^ADN,20,10^FD\(productPrice) (\(productWeigh))^FS"
            testLabel.append(start)
            testLabel.append(barcode1)
            testLabel.append(barcode2)
            testLabel.append(barcode3)
            testLabel.append(productLine1)
            testLabel.append(productLine2)
            testLabel.append(productLine3)
            testLabel.append(printQuantity)
            testLabel.append(end)
            
        }
        
        //for iphones the end commnd is being stripped out, so we are appending againg the end command
        if UIDevice.current.userInterfaceIdiom == .phone {
            testLabel.append(end)
        }
        
        if let unsafePtr = testLabel.toPointer() {
            let data = Data(bytes: unsafePtr, count: testLabel.count)
            writeToPrinter(with: data)
        }
        
    }
    
}

//CPCL
extension ZebraPrintManager {
    
    private func printLabelCPCLTwoByOne(with product:[String: Any], min: String, max: String) {
        if let data = printLabelTwoByOne(product: product, min: min, max: max).data(using: .utf8) {
            writeToPrinter(with: data)
        }
    }
    
    private func printLabelCPCLThreeByTwo(with product:[String: Any], min: String, max: String) {
        if let data = printLabelThreeByTwo(product: product, min: min, max: max).data(using: .utf8) {
            writeToPrinter(with: data)
        }
    }
    
    
    private func printLabelTwoByOne(product:[String: Any], min: String, max: String ) -> String {
        
        
        let productBarcode = product["productBarcode"] as? String ?? ""
        let productType = product["productType"] as? String ?? ""
        let productName = product["productName"] as? String ?? ""
        let productWeigh = product["productWeigh"] as? String ?? ""
        let productPrice = product["productPrice"] as? String ?? ""
        
        let barcode = printerBarCodeFormat(width: 2, ratio: 1, height: 50, x: 230, y: 100, content: productBarcode)
        let skuUPCCode = printerTextField(font: 4, size: 2 , x: 230, y: 155, content: productBarcode)
        let productNameAndType = printerTextField(font: 20, size: 10, x:230 , y:200 , content: "(\(productType)) \(productName)")
        let productPriceAndWeigh = printerTextField(font: 20, size:  10, x: 230, y: 230, content: "\(productPrice) (\(productWeigh))     \(min)\(max)")
        return "\(CommonPrintingFormat.start.rawValue) \n\(barcode) \n\(skuUPCCode) \n\(productNameAndType) \n\(productPriceAndWeigh)\(CommonPrintingFormat.end.rawValue)"
    }
    
    private func printLabelThreeByTwo(product:[String: Any], min: String, max: String ) -> String {
        
        
        let productBarcode = product["productBarcode"] as? String ?? ""
        let productType = product["productType"] as? String ?? ""
        let productName = product["productName"] as? String ?? ""
        let productWeigh = product["productWeigh"] as? String ?? ""
        let productPrice = product["productPrice"] as? String ?? ""
        
        let barcode = printerBarCodeFormat(width: 2, ratio: 1, height: 50, x: 150, y: 50, content: productBarcode)
        let skuUPCCode = printerTextField(font: 4, size: 2 , x: 150, y: 60, content: productBarcode)
        let productNameAndType = printerTextField(font: 20, size: 10, x:150 , y:110 , content: "(\(productType)) \(productName)")
        let productPriceAndWeigh = printerTextField(font: 20, size:  10, x: 150, y: 140, content: "\(productPrice) (\(productWeigh))     \(min)\(max)")
        return "\(CommonPrintingFormat.start.rawValue) \n\(barcode) \n\(skuUPCCode) \n\(productNameAndType) \n\(productPriceAndWeigh)\(CommonPrintingFormat.end.rawValue)"
    }
    
    private func printerTextField(font:Int, size: Int, x:Int, y: Int, content: String) -> String {
        return "TEXT \(font) \(size) \(x) \(y) \(content)"
    }
    
    private func printMultiLineTextField(linesHeight: Int, font:Int, size: Int, x:Int, y: Int, content: String) -> String {
        return "ML \(linesHeight)\nTEXT \(font) \(size) \(x) \(y) \n\(content)\nENDML\nENDML"
    }
    
    private func printerBarCodeFormat(width: Int, ratio: Int, height: Int, x: Int, y:Int, content: String) -> String {
        return "BARCODE 128 \(width) \(ratio) \(height) \(x) \(y) \(content)"
    }
    
}
