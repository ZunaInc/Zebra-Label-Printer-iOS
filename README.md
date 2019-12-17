# Zebra-Label-Printer-iOS

Zebra label printer example project for iOS writen in swift using a static library built on top of Zebra Label Printer SDK.

### Installation

- Add libZebraMultiOSLabelPrinterSwift.a file and ZebraMultiOSLabelPrinterSwift.swiftmodule(contains necessary files) directectory to your project (Refer the sample project for necessary files).
- In build settings search for Swift Compiler - Search Path, set "Import Paths" for your project, that would be "$(PROJECT_DIR)" if you have just added directly to your project.



### Usage

```
import import UIKit
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
     let yourCustomCommand = ""
     printManager.printCutomLabel(data: yourCustomCommand, numberOfPrints: 3)
   }
}

func getPrinterLanguage() {
    DispatchQueue.global().async {
     let printerLanguage = printManager.getPrinterLanguage()
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

