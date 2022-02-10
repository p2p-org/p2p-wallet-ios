//
//  WLNavigationBar.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation
import UIKit

class WLNavigationBar: BEView {
    lazy var stackView = UIStackView(axis: .horizontal, alignment: .center, distribution: .equalCentering, arrangedSubviews: [
        leftItems,
        centerItems,
        rightItemsWrapper
    ])
    
    lazy var leftItems = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
        backButton,
        UIView.spacer
    ])
    lazy var centerItems = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
        titleLabel
    ])
    
    private lazy var rightItemsWrapper = rightItems.padding(.zero.modifying(dRight: 6))
    lazy var rightItems = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
        UIView.spacer
    ])
    
    lazy var backButton = UIImageView(width: 14, height: 24, image: UIImage(systemName: "chevron.left"), tintColor: .h5887ff)
        .padding(.init(x: 6, y: 4))
    lazy var titleLabel = UILabel(textSize: 17, weight: .semibold, numberOfLines: 1, textAlignment: .center)
    
    override func commonInit() {
        super.commonInit()
        stackView.spacing = 8
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 12, y: 8))
        
        leftItems.widthAnchor.constraint(equalTo: rightItemsWrapper.widthAnchor).isActive = true
        
        backgroundColor = .background
    }
    
    func setTitle(_ title: String?) {
        titleLabel.text = title
    }
}

class NewWLNavigationBar: BECompositionView {
    private var backButton: UIView!
    private(set) var titleLabel: UILabel!
    private var separatorEnable: Bool
    
    private let actions: UIView
    
    let initialTitle: String?
    
    init(initialTitle: String? = nil, separatorEnable: Bool = true) {
        self.initialTitle = initialTitle
        self.separatorEnable = separatorEnable
        self.actions = BEContainer()
        super.init()
    }
    
    init(initialTitle: String? = nil, separatorEnable: Bool = true, @BEViewBuilder actions: Builder) {
        self.initialTitle = initialTitle
        self.separatorEnable = separatorEnable
        self.actions = actions().build()
        super.init()
    }
    
    @discardableResult
    func onBack(_ callback: @escaping () -> Void) -> Self {
        backButton.onTap(callback)
        return self
    }

    @discardableResult
    func backIsHidden(_ isHidden: Bool) -> Self {
        backButton.isHidden = isHidden
        return self
    }
    
    override func build() -> UIView {
        BESafeArea {
            UIStackView(axis: .vertical, alignment: .fill) {
                UIStackView(axis: .horizontal, alignment: .fill, distribution: .equalCentering) {
                    // Back button
                    UIStackView(axis: .horizontal) {
                        UIImageView(width: 14, height: 24, image: UIImage(systemName: "chevron.left"), tintColor: .h5887ff)
                            .padding(.init(x: 6, y: 4))
                            .setup({ view in
                                self.backButton = view
                                self.backButton.isUserInteractionEnabled = true
                            })
                    }
                    
                    // Title
                    UILabel(text: initialTitle, textSize: 17, weight: .semibold, numberOfLines: 1, textAlignment: .center)
                        .setupWithType(UILabel.self) { view in self.titleLabel = view }
                    
                    // Actions
                    actions
                }.padding(.init(x: 12, y: 8))
                if separatorEnable { UIView.defaultSeparator() }
            }.frame(height: 50)
        }
    }
    
    override func layout() {
        backButton.widthAnchor.constraint(equalTo: actions.widthAnchor).isActive = true
    }
    
}

final class ModalNavigationBar: UIStackView {
    private let navigationBar = WLNavigationBar()

    private let closeHandler: () -> Void

    init(
        title: String?,
        rightButtonTitle: String,
        closeHandler: @escaping () -> Void
    ) {
        self.closeHandler = closeHandler

        super.init(frame: .zero)

        configureSelf()
        configureNavigationBar(title: title, rightButtonTitle: rightButtonTitle)
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSelf() {
        axis = .vertical
        
        addArrangedSubviews {
            UIView(height: 14, backgroundColor: .fafafc.onDarkMode(.clear))
            navigationBar
            UIView(height: 0.5, backgroundColor: .black.withAlphaComponent(0.3))
        }
    }

    private func configureNavigationBar(title: String?, rightButtonTitle: String) {
        navigationBar.backButton.isHidden = true
        navigationBar.backgroundColor = .fafafc.onDarkMode(.clear)
        navigationBar.titleLabel.text = title
        let closeButton = UIButton(
            label: rightButtonTitle,
            labelFont: .systemFont(ofSize: 17, weight: .bold),
            textColor: .h5887ff
        )
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        navigationBar.rightItems.addArrangedSubview(closeButton)
    }

    @objc
    func close() {
        closeHandler()
    }
}
