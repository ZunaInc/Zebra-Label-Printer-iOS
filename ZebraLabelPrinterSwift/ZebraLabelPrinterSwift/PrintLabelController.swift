//
//  POS_PrintProductLabelController.swift
//  ZebraLabelPrinterSwift
//
//  Created by Sachin Pampannavar on 11/5/19.
//  Copyright © 2019 Goalsr. All rights reserved.
//

import UIKit
import ZebraMultiOSLabelPrinterSwift

let quantityCell = "QuantityCell"
let printLabelCell = "PrintLabelCell"

class PrintLabelController: UITableViewController {
    
    //MARK: Properties
    var printManager = ZebraMultiOSLabelPrinterSwift.shared
    var skuBarcode = "1234567890"
    var numberOfPrints = 1
    var skuBarcodeImage: UIImage!
    var productName = "Product 01"
    var productMeasurement = "Gram"
    var productCategory = "Category 01"
    var productPrice = "50.00"
    
    enum Section: Int {
        case labelSize = 0
        case label
        case numberOfPrints
    }
    
    enum Descriptor: String {
        case code128 = "CICode128BarcodeGenerator"
        case pdf417 = "CIPDF417BarcodeGenerator"
        case aztec = "CIAztecCodeGenerator"
        case qr = "CIQRCodeGenerator"
    }
    
    var selectedLabelSizeIndex = 0
    
    let labelSizes = ["2 x 1", "3 x 2"]
    let labelSizeEnumValues = [LabelSize.TwoByOne, LabelSize.ThreeByTwo]
    
    var navigationTitleView: NavigationTitleWithLoader?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
    }
    
    func initialSetup() {
        
        navigationTitleView = NavigationTitleWithLoader(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        navigationTitleView?.title = "Print Label"
        navigationTitleView?.isLoading = false
        
        //Zebra Printer************
        printManager.connectionDelegate = self
        //*************************
        
        self.tableView.register(UINib(nibName: quantityCell, bundle: nil), forCellReuseIdentifier: quantityCell)
        self.tableView.register(UINib(nibName: printLabelCell, bundle: nil), forCellReuseIdentifier: printLabelCell)
        
        self.navigationItem.titleView = self.navigationTitleView
        self.navigationController?.navigationBar.tintColor = UIColor.blue
        let printButton = UIBarButtonItem(title: "Print", style: .plain, target: self, action: #selector(self.printAction))
        
        self.navigationItem.rightBarButtonItems = [printButton]
        
        if !self.skuBarcode.isEmpty {
            skuBarcodeImage = generate(from: skuBarcode, descriptor: Descriptor.code128, size: CGSize(width: 447, height: 164))
        }
        
        self.tableView.tableHeaderView = self.tableViewHeaderView()
        
    }
    
    private func generate(from string: String, descriptor: Descriptor, size: CGSize) -> UIImage? {
        
        let filterName = descriptor.rawValue
        guard let data = string.data(using: .ascii),
            let filter = CIFilter(name: filterName) else {
                return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        guard let image = filter.outputImage else {
            return nil
        }
        
        let imageSize = image.extent.size
        let transform = CGAffineTransform(scaleX: size.width / imageSize.width, y: size.height / imageSize.height)
        let scaledImage = image.transformed(by: transform)
        let barCodeImage:UIImage = UIImage.init(ciImage: scaledImage)
        
        return barCodeImage
    }
    
    func tableViewHeaderView() -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 21))
        
        
        let label = UILabel()
        let connectReaderButton = UIButton(type: .system)
        
        headerView.addSubview(label)
        headerView.addSubview(connectReaderButton)
        
        headerView.addConstraintsWithFormat("H:|-0-[v0]-0-|", views: label)
        headerView.addConstraintsWithFormat("V:|-0-[v0]-0-|", views: label)
        
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        
        var labelText = ""
        
        if self.printManager.isConnected {
            headerView.backgroundColor = UIColor.green
            labelText = "Printer is connected"
        } else {
            labelText = "Printer is not connected"
            headerView.backgroundColor = UIColor.red
        }
        
        label.text = labelText
        
        return headerView
    }
    
    
    @objc func printAction(){
        
        if self.printManager.isConnected {
            printLabelZebraPrinter()
        }
    }
    
    func printLabelZebraPrinter() {
        let skuUPC = self.skuBarcode
        
        let retailPrice = Double(self.productPrice) ?? 0.0
        
        let retailPriceFormattedToLocale = formatToLocale(convertValue: retailPrice)
        
        let productType = self.productCategory
        let productName = self.productName
        let productWeigh = self.productMeasurement
        
        var product = [String: Any]()
        product["productBarcode"] = skuUPC
        product["productType"] = productType
        product["productName"] = productName
        product["productWeigh"] = productWeigh
        product["productPrice"] = retailPriceFormattedToLocale
        
        let labelSize = self.labelSizeEnumValues[self.selectedLabelSizeIndex]
        DispatchQueue.global().async {
            self.navigationTitleView?.isLoading = true
            //self.printManager.printLabelAndBarcode(product: product, numberOfPrints: self.numberOfPrints, labelSize: labelSize)
            self.printManager.printSampleLabelAndBarcode(numberOfPrints: self.numberOfPrints, labelSize: labelSize)
        }
        
    }
    
    private func formatToLocale(convertValue:Any?, localeString: String = "en_US") -> String {
        
        let formatter = NumberFormatter()
        
        formatter.locale = Locale.current
        
        formatter.numberStyle = .currency
        
        var formattedValue:String?
        formattedValue = formatter.string(for: convertValue)
        
        return formattedValue ?? ""
        
    }
    
    @objc func incrementPrintCount() {
        self.numberOfPrints += 1
        self.tableView.reloadData()
    }
    
    @objc func decrementPrintCount() {
        if self.numberOfPrints == 1 { return }
        self.numberOfPrints -= 1
        self.tableView.reloadData()
    }
    
    
}

extension PrintLabelController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Section.labelSize.rawValue {
            return self.labelSizes.count
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Section.labelSize.rawValue {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "CELL_ID")
            cell.textLabel?.text = self.labelSizes[indexPath.row]
            if indexPath.row == self.selectedLabelSizeIndex {
                cell.accessoryType = .checkmark
            }
            return cell
        }
        else if indexPath.section == Section.label.rawValue{
            let barcodeLabelCell = tableView.dequeueReusableCell(withIdentifier: printLabelCell, for: indexPath) as! PrintLabelCell
            barcodeLabelCell.tintColor = UIColor.green
            barcodeLabelCell.selectionStyle = .none
            barcodeLabelCell.barCodeImageView.image = skuBarcodeImage
            
            let retailPrice = Double(self.productPrice) ?? 0.0
            
            let retailPriceFormattedToLocale = formatToLocale(convertValue: retailPrice)
            
            barcodeLabelCell.skuUPCLable.text = self.skuBarcode
            
            barcodeLabelCell.productName.text = "(\(self.productCategory)) \(self.productName)\n\(retailPriceFormattedToLocale) (\(self.productMeasurement))"
            
            barcodeLabelCell.layer.borderWidth = 2.0
            return barcodeLabelCell
        } else {
            let qntyCell = tableView.dequeueReusableCell(withIdentifier: quantityCell, for: indexPath) as! QuantityCell
            qntyCell.selectionStyle = .none
            qntyCell._quantityLabel.text = "\(numberOfPrints)"
            qntyCell._addBtn.addTarget(self, action: #selector(self.incrementPrintCount), for: .touchUpInside)
            qntyCell._removeBtn.addTarget(self, action: #selector(self.decrementPrintCount), for: .touchUpInside)
            return qntyCell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Section.labelSize.rawValue {
            self.selectedLabelSizeIndex = indexPath.row
        }
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == Section.labelSize.rawValue {
            return 44
        }
        else if indexPath.section == Section.label.rawValue {
            return 180
        }
        return 80
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Section.labelSize.rawValue {
            return "Label Size"
        } else if section == Section.numberOfPrints.rawValue {
            return "Number of prints"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == Section.labelSize.rawValue {
            return "Width(inch) x height(inch)"
        }
        return nil
    }
}

//Zebra printer *********
extension PrintLabelController: EAAccessoryManagerConnectionStatusDelegate {
    func didChangePrinterConnectionStatus() {
        DispatchQueue.main.async {
            self.tableView.tableHeaderView = self.tableViewHeaderView()
        }
    }
    
    func didFailedToPrint(error: PrintError) {
        print(error.rawValue)
        DispatchQueue.main.async {
            self.navigationTitleView?.isLoading = false
        }
    }
    
    func didPrintSuccessfully() {
        DispatchQueue.main.async {
            self.navigationTitleView?.isLoading = false
        }
    }
    
    
}

