//
//  BaseCollectionReusableView.swift
//  BECollectionView_Example
//
//  Created by Chung Tran on 07/07/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class BaseCollectionReusableView: UICollectionReusableView {
    open var padding: UIEdgeInsets {.zero}
    public lazy var stackView = UIStackView(forAutoLayout: ())
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    @available(*, unavailable,
    message: "Loading this view from a nib is unsupported in favor of initializer dependency injection."
    )
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func commonInit() {
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: padding)
    }
}
