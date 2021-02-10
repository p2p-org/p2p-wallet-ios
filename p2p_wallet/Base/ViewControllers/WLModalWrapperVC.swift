//
//  WLModalWrapperVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation

class WLModalWrapperVC: WLModalVC {
    override var padding: UIEdgeInsets {.init(x: .defaultPadding, y: .defaultPadding)}
    var vc: UIViewController
    var titleImage: UIImage?
    
    init(wrapped: UIViewController) {
        vc = wrapped
        super.init()
    }
    
    override func setUp() {
        super.setUp()
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(vc)
        // collectionView(didSelectItemAt) would not be called if
        // we add vc.view inside stackView or containerView, so I
        // add vc.view directly into `view`
        view.addSubview(vc.view)
        containerView.constraintToSuperviewWithAttribute(.bottom)?
            .isActive = false
        vc.view.autoPinEdge(.top, to: .bottom, of: containerView)
        vc.view.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        vc.didMove(toParent: self)
        
        if let title = title {
            addHeader(title: title, image: titleImage)
        }
    }
    
    // MARK: - Helpers
    private func addHeader(title: String, image: UIImage? = nil) {
        stackView.axis = .horizontal
        stackView.spacing = 16
        var subviews = [UIView]()
        if let image = image {
            subviews.append(
                UIImageView(width: 24, height: 24, image: image, tintColor: .white)
                    .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12)
            )
        }
        subviews.append(
            UILabel(text: title, textSize: 17, weight: .semibold)
        )
        stackView.addArrangedSubviews(subviews)
        
        let separator = UIView.separator(height: 1, color: .separator)
        containerView.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }
}
