//
//  BottomFlexibleHeightVC.swift
//  Commun
//
//  Created by Chung Tran on 9/30/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import Foundation
import UIKit

class BottomFlexibleHeightVC: BaseVStackVC, UIViewControllerTransitioningDelegate {
    // MARK: - Nested type
    class PresentationController: FlexibleHeightPresentationController {
        override func calculateFittingHeightOfPresentedView(targetWidth: CGFloat) -> CGFloat {
            let vc = presentedViewController as! BottomFlexibleHeightVC
            return vc.fittingHeightInContainer(safeAreaFrame: safeAreaFrame!)
        }
    }
    
    func fittingHeightInContainer(safeAreaFrame: CGRect) -> CGFloat {
        var height: CGFloat = 0
        
        // calculate header
        height += 20 // 20-headerStackView
        
        height += headerStackView.fittingHeight(targetWidth: safeAreaFrame.width - 20 - 20)
        
        height += 20 // headerStackView-20
        
        height += scrollView.contentView.fittingHeight(targetWidth: safeAreaFrame.width - padding.left - padding.right)

        return height
    }
    
    override var padding: UIEdgeInsets {UIEdgeInsets(all: 20)}
    
    lazy var headerStackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill)
    lazy var titleLabel = UILabel(textSize: 17, weight: .semibold)
    lazy var closeButton = UIButton.close()
        .onTap(self, action: #selector(back))
    
    override var title: String? {
        didSet {titleLabel.text = title}
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        // set up header
        headerStackView.addArrangedSubviews([titleLabel, .spacer, closeButton])
        view.addSubview(headerStackView)
        headerStackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(all: 20), excludingEdge: .bottom)
        
        scrollView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        scrollView.autoPinEdge(.top, to: .bottom, of: headerStackView)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentationController(presentedViewController: presented, presenting: presenting)
    }
}
