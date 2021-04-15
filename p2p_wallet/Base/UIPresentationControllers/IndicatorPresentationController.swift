//
//  IndicatorPresentationController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/04/2021.
//

import Foundation

class IndicatorPresentationController: BEDimmingPresentationController {
    // MARK: - Subviews
    private lazy var indicatorView = UIView(width: 71, height: 5, backgroundColor: .vcBackground, cornerRadius: 2.5)
    private lazy var mainContentView = UIView(backgroundColor: .vcBackground)
    private lazy var contentView: UIView = {
        let contentView = UIView(backgroundColor: .clear)
        contentView.addSubview(indicatorView)
        indicatorView.autoPinEdge(toSuperviewEdge: .top)
        indicatorView.autoAlignAxis(toSuperviewAxis: .vertical)
        
        contentView.addSubview(mainContentView)
        mainContentView.autoPinEdge(.top, to: .bottom, of: indicatorView, withOffset: 8)
        mainContentView.autoPinEdge(toSuperviewSafeArea: .leading)
        mainContentView.autoPinEdge(toSuperviewSafeArea: .trailing)
        mainContentView.autoPinEdge(toSuperviewEdge: .bottom)
        return contentView
    }()
    
    override var presentedView: UIView? {
        contentView
    }
    
    // MARK: - Layout events
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        // Double-checking this here in case nested modals stteal our presented
        // view controller's view, since that breaks all of our constraints.
        addPresentedViewToMainContentView()
    }
    
    // MARK: - Transition
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        addContentView()
        addPresentedViewToMainContentView()
        
        containerView?.layoutIfNeeded()
        mainContentView.roundCorners([.topLeft, .topRight], radius: 20)
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        // Remove views if transition was aborted.
        //
        // If transition completed normally, nothing to do.
        if !completed {
            contentView.removeFromSuperview()
        }
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        // Remove views if transition completed.
        //
        // If transition was aborted, nothing to do.
        if completed {
            contentView.removeFromSuperview()
        }
    }
    
    // MARK: - Helpers
    private func addContentView() {
        guard let containerView = containerView else {return}
        
        containerView.addSubview(contentView)
        contentView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
//        contentView.autoPinEdge(.top, to: .top, of: containerView, withOffset: 0, relation: .greaterThanOrEqual)
    }
    
    private func addPresentedViewToMainContentView() {
        guard !presentedViewController.view.isDescendant(of: mainContentView)
        else {return}
        
        presentedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        mainContentView.addSubview(presentedViewController.view)
        presentedViewController.view.autoPinEdgesToSuperviewEdges()
    }
}
