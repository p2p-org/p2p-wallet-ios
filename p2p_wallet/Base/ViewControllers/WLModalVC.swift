//
//  WLModalVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/12/2020.
//

import Foundation

class WLIndicatorModalVC: BaseVC {
    lazy var containerView = UIView(backgroundColor: .background)
    // bottomView for covering safe area
    lazy var bottomView = UIView(backgroundColor: containerView.backgroundColor)
    var swipeGesture: UIGestureRecognizer?
    
    // MARK: - Initializers
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(bottomView)
        bottomView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        bottomView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            .isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        containerView.roundCorners([.topLeft, .topRight], radius: 20)
    }
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .clear
        let topGestureView = UIView(width: 71, height: 5, backgroundColor: .vcBackground, cornerRadius: 2.5)
        view.addSubview(topGestureView)
        topGestureView.autoPinEdge(toSuperviewSafeArea: .top)
        topGestureView.autoAlignAxis(toSuperviewAxis: .vertical)
        
        view.addSubview(containerView)
        containerView.autoPinEdge(.top, to: .bottom, of: topGestureView, withOffset: 8)
        containerView.autoPinEdge(toSuperviewSafeArea: .leading)
        containerView.autoPinEdge(toSuperviewSafeArea: .trailing)
        containerView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard()
        
        containerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        
        if modalPresentationStyle == .custom {
            swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(viewDidSwipe(_:)))
            view.addGestureRecognizer(swipeGesture!)
            view.isUserInteractionEnabled = true
        }
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc func viewDidSwipe(_ gestureRecognizer: UIPanGestureRecognizer) {
        (presentationController as? ResizablePresentationController)?.presentedViewDidSwipe(gestureRecognizer: gestureRecognizer)
    }
}

class WLModalVC: WLIndicatorModalVC {
    var padding: UIEdgeInsets {.init(x: 0, y: 20)}
    lazy var stackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill)
    
    override func setUp() {
        super.setUp()
        containerView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: padding)
    }
}
