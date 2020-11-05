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

class WLBottomSheet: BottomFlexibleHeightVC {
    var panGestureRecognizer: UIPanGestureRecognizer?
    var interactor: SwipeDownInteractor?
    
    var backgroundColor: UIColor = .background {
        didSet { view.backgroundColor = backgroundColor }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        interactor = SwipeDownInteractor()
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        view.addGestureRecognizer(panGestureRecognizer!)
        
        view.backgroundColor = backgroundColor
    }
    
    @objc func panGestureAction(_ sender: UIPanGestureRecognizer) {
        let percentThreshold: CGFloat = 0.3

        // convert y-position to downward pull progress (percentage)
        let translation = sender.translation(in: view)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)
        
        guard let interactor = interactor else {
            return
        }
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            dismiss(animated: true, completion: nil)
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
        case .ended:
            interactor.hasStarted = false
            interactor.cancel()
        default:
            break
        }
    }
    
    func disableSwipeDownToDismiss() {
        guard let gesture = panGestureRecognizer else {return}
        view.removeGestureRecognizer(gesture)
    }
}

extension WLBottomSheet {
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor?.hasStarted == true ? interactor : nil
    }
}
