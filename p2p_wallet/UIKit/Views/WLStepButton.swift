//
//  WLStepButton.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/11/2021.
//

import Foundation
import UIKit
import RxSwift

// MARK: - Builders
extension WLStepButton {
    /// Main button for recommended action
    static func main(
        image: UIImage? = nil,
        imageSize: CGSize = .init(width: 24.adaptiveHeight, height: 24.adaptiveHeight),
        text: String?
    ) -> WLStepButton {
        .init(
            enabledBgColor: .h5887ff,
            enabledTintColor: .white,
            disabledBgColor: .aeaeb2,
            disabledTintColor: .d1d1d6,
            text: text,
            image: image,
            imageSize: imageSize
        )
    }
    
    /// Sub button for not-recommended action
    static func sub(
        image: UIImage? = nil,
        imageSize: CGSize = .init(width: 24.adaptiveHeight, height: 24.adaptiveHeight),
        text: String?
    ) -> WLStepButton {
        .init(
            enabledBgColor: .clear,
            enabledTintColor: .h5887ff,
            disabledTintColor: .textSecondary,
            text: text
        )
    }
}

// MARK: - Main class
class WLStepButton: BEView {
    // MARK: - Properties
    var enabledBgColor: UIColor {
        didSet {
            setUp()
        }
    }
    var enabledTintColor: UIColor {
        didSet {
            setUp()
        }
    }
    var disabledBgColor: UIColor? {
        didSet {
            setUp()
        }
    }
    var disabledTintColor: UIColor? {
        didSet {
            setUp()
        }
    }
    
    var isEnabled: Bool = true {
        didSet {
            setUp()
        }
    }
    
    // MARK: - Subviews
    private lazy var stackView = UIStackView(
        axis: .horizontal,
        spacing: 12.adaptiveHeight,
        alignment: .center,
        distribution: .fill
    ) {
        imageView
        label
    }
    fileprivate lazy var imageView = UIImageView()
    fileprivate lazy var label = UILabel(
        textSize: 17.adaptiveHeight,
        weight: .medium,
        textColor: enabledTintColor,
        numberOfLines: 2,
        textAlignment: .center
    )
        .withContentCompressionResistancePriority(.required, for: .horizontal)
    
    // MARK: - Initializer
    init(
        enabledBgColor: UIColor,
        enabledTintColor: UIColor,
        disabledBgColor: UIColor? = nil,
        disabledTintColor: UIColor? = nil,
        text: String?,
        image: UIImage? = nil,
        imageSize: CGSize = .init(width: 24.adaptiveHeight, height: 24.adaptiveHeight)
    ) {
        self.enabledBgColor = enabledBgColor
        self.enabledTintColor = enabledTintColor
        super.init(frame: .zero)
        self.disabledBgColor = disabledBgColor
        self.disabledTintColor = disabledTintColor
        
        configureForAutoLayout()
        
        // min height is relative 56
        autoSetDimension(.height, toSize: 56.adaptiveHeight)
        
        // round corner
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        // stackView
        addSubview(stackView)
        stackView.autoCenterInSuperview()
        stackView.autoPinEdge(toSuperviewEdge: .top, withInset: 0, relation: .greaterThanOrEqual)
        stackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0, relation: .greaterThanOrEqual)
        stackView.autoPinEdge(toSuperviewEdge: .leading, withInset: 16, relation: .greaterThanOrEqual)
        stackView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16, relation: .greaterThanOrEqual)
        
        // image
        setImage(image: image, imageSize: imageSize)
        
        // text
        label.text = text
        
        setUp()
    }
    
    // MARK: - Methods

    func setImage(image: UIImage?, imageSize: CGSize) {
        if let image = image {
            imageView.isHidden = false
            imageView.autoSetDimensions(to: imageSize)
            imageView.image = image
        } else {
            imageView.isHidden = true
        }
    }

    func setTitle(text: String?) {
        label.text = text
    }

    private func setUp() {
        // user interaction
        isUserInteractionEnabled = isEnabled
        
        // background
        backgroundColor = isEnabled ? enabledBgColor : disabledBgColor
        
        // text color
        label.textColor = isEnabled ? enabledTintColor : (disabledTintColor ?? enabledTintColor)
        
        // imageView tintColor
        imageView.tintColor = isEnabled ? enabledTintColor : (disabledTintColor ?? enabledTintColor)
    }
}

extension Reactive where Base: WLStepButton {
    var isEnabled: Binder<Bool> {
        Binder(base) { view, isEnabled in
            view.isEnabled = isEnabled
        }
    }
    
    var text: Binder<String?> {
        Binder(base) { view, text in
            view.label.text = text
        }
    }
    
    var image: Binder<UIImage?> {
        Binder(base) { view, image in
            view.imageView.image = image
            view.imageView.isHidden = image == nil
        }
    }

//    var tapGesture: Any {
//        base.rx.event.bind(onNext: { recognizer in
//            print("touches: \(recognizer.numberOfTouches)") //or whatever you like
//        })
//    }
}
