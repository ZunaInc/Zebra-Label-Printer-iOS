//
//  Extensions.swift
//  POS
//
//  Created by Sachin on 02/01/19.
//  Copyright © 2019 Goalsr. All rights reserved.
//

import UIKit

extension UIView {
    func addConstraintsWithFormat(_ format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
    }     
    
}

extension String {
    func toPointer() -> UnsafePointer<UInt8>? {        
        guard let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false) else { return nil}
        let dataMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        
        //Copies the bytes to the Mutable Pointer
        data.copyBytes(to: dataMutablePointer, count: data.count)
        
        //Cast to regular UnsafePointer
        let dataPointer = UnsafePointer<UInt8>(dataMutablePointer)
        return dataPointer
        
    }
}

















