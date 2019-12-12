//
//  NavigationTitleWithLoader.swift
//  ZebraLabelPrinterSwift
//
//  Created by Sachin Pampannavar on 12/10/19.
//  Copyright © 2019 Sachin Pampannavar. All rights reserved.
//

import UIKit

class NavigationTitleWithLoader: UIView {
    
    var title: String? {
        didSet {
            if let title = title {
                DispatchQueue.main.async {
                    self.titleLabel.text = title
                }
            }
        }
    }
    var isLoading: Bool? {
        didSet {
            if let isLoading = isLoading {
                if isLoading {
                    DispatchQueue.main.async {
                        self.loader.isHidden = false
                        self.loader.startAnimating()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.loader.isHidden = true
                        self.loader.stopAnimating()
                    }
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = self.title
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.textAlignment = .center
        return l
    }()
    
    lazy var loader: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .gray)
        return ai
    }()
    
    func setupView() {
        addSubview(titleLabel)
        addSubview(loader)
        
        addConstraintsWithFormat("H:|[v0]-8-[v1(30)]|", views: titleLabel, loader)
        addConstraintsWithFormat("V:|[v0]|", views: titleLabel)
        addConstraintsWithFormat("V:|[v0(30)]|", views: loader)
    }
    
}
