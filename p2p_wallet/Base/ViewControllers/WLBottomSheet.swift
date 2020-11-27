//
//  WLBottomSheet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/12/20.
//

import Foundation

class WLBottomSheet: FlexibleHeightVC {
    var panGestureRecognizer: UIPanGestureRecognizer?
    var interactor: SwipeDownInteractor?
    
    var backgroundColor: UIColor = .background {
        didSet { view.backgroundColor = backgroundColor }
    }
    
    override var title: String? {
        didSet {titleLabel.text = title}
    }
    
    override var padding: UIEdgeInsets {UIEdgeInsets(all: 20)}
    
    lazy var headerStackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill)
    lazy var titleLabel = UILabel(textSize: 17, weight: .semibold)
    lazy var closeButton = UIButton.close()
        .onTap(self, action: #selector(back))
    
    init() {
        super.init(position: .bottom)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        interactor = SwipeDownInteractor()
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        view.addGestureRecognizer(panGestureRecognizer!)
        
        view.backgroundColor = backgroundColor
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
    
    override func fittingHeightInContainer(frame: CGRect) -> CGFloat {
        var height = super.fittingHeightInContainer(frame: frame)
        
        // calculate header
        height += 20 // 20-headerStackView
        
        height += headerStackView.fittingHeight(targetWidth: frame.width - 20 - 20)
        
        height += 20 // headerStackView-20

        return height + view.safeAreaInsets.bottom + padding.bottom
    }
    
    override func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = super.presentationController(forPresented: presented, presenting: presenting, source: source) as! PresentationController
        pc.roundedCorner = [.topLeft, .topRight]
        return pc
    }
}

extension WLBottomSheet {
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor?.hasStarted == true ? interactor : nil
    }
}
