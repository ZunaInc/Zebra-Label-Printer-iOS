# Zebra-Label-Printer-iOS

Zebra label printer example project for iOS written in swift using a static library built on top of Zebra Label Printer SDK. Tested and working on Zebra ZD420.

### Requirement
- iOS 10 or above.
- Swift 5 or above.
- Runs only on device (Simulator not supported).

### Limitations
- Works with only BT or BLE.
- Supports only 2" x 1" and 3" x 2" label sizes.
- Supports only ZPL Language. 


### Installation
- Download the sample project.
- Locate libZebraMultiOSLabelPrinterSwift.a file and ZebraMultiOSLabelPrinterSwift.swiftmodule(contains architecture files) directory.
- Create a new group in your new or existing project.
- Add libZebraMultiOSLabelPrinterSwift.a file and ZebraMultiOSLabelPrinterSwift.swiftmodule directory to the created group.
- Open build setting -> search for "Library Search Paths" and set the path to "$(PROJECT_DIR)/Created-Group-Name". If you have added directly to your project, the path would be "$(PROJECT_DIR)".
- Open build setting -> search for Swift Compiler - Search Path and set the "Import Paths" to "$(PROJECT_DIR)/Created-Group-Name". If you have added directly to your project, the path would be "$(PROJECT_DIR)".



### Usage

```swift
import UIKit
import ZebraMultiOSLabelPrinterSwift

class PrintLabelController: UIViewController {

      //MARK: Properties
      var printManager = ZebraMultiOSLabelPrinterSwift.shared
      
      override func viewDidLoad() {
           super.viewDidLoad()
           printManager.connectionDelegate = self
      }
      
      func printSampleLabel() {
           DispatchQueue.global().async {
           printManager.printSampleLabelAndBarcode(numberOfPrints: 2, labelSize: .TwoByOne)
         }
      }
      
      func printCustomlabel() {
          DispatchQueue.global().async {
          let yourCustomCommand = "^XA^FO50,50^A0,32,25^FDZEBRA^FS^FO50,150^A0,32,25^FDPROGRAMMING^FS^FO50,250^A0,32,25^FDLANGUAGE^FS^XZ"
           
           /*
           Some basics of ZPL. Find more information here : https://www.zebra.com/content/dam/zebra/manuals/printers/common/programming/zpl-zbi2-pm-en.pdf
           
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
           
           printManager.printCutomLabel(data: yourCustomCommand, numberOfPrints: 3)
         }
      }
      
      func getPrinterLanguage() {
          //Returns string either "ZPL" or "CPCL"
          DispatchQueue.global().async {
           let printerLanguage = printManager.getPrinterLanguage()
         }
      }
      
      func getPrinterConnectionStatus() {
           let isConnected = printManager.isConnected
      }
}

}

extension PrintLabelController: EAAccessoryManagerConnectionStatusDelegate {

      func didChangePrinterConnectionStatus() {
         DispatchQueue.main.async {
           //Update UI
         }
      }

      func didFailedToPrint(error: PrintError) {
          print(error.rawValue)
          DispatchQueue.main.async {
           //Update UI
          }
      }
      
      func didPrintSuccessfully() {
          DispatchQueue.main.async {
           //Update UI
          }
      }
}
```
### Sample Output Label

![alt text](https://github.com/ZunaInc/Zebra-Label-Printer-iOS/blob/master/Media/sampleOutPut.png)


### Contact Us

- Website : [**Zuna Inc**](https://zunaco.com)
- Email : <sales@zunaco.com>

