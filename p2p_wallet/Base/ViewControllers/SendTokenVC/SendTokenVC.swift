//
//  SendTokenVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/12/20.
//

import Foundation
import RxSwift

class SendTokenVC: BEPagesVC, LoadableView {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .normal(backgroundColor: .vcBackground)
    }
    var loadingViews: [UIView] { [containerView, sendButton] }
    
    lazy var scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: UIEdgeInsets(top: 44, left: 16, bottom: 0, right: 16))
    lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
    lazy var sendButton = WLButton.stepButton(type: .main, label: L10n.sendNow)
    
    lazy var errorLabel = UILabel(textSize: 17, weight: .semibold, textColor: .textBlack, numberOfLines: 0, textAlignment: .center)
    
    lazy var viewModel = WalletVM.ofCurrentUser
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        title = L10n.sendCoins
        
        scrollView.contentView.backgroundColor = .textWhite
        scrollView.contentView.layer.cornerRadius = 16
        scrollView.contentView.layer.masksToBounds = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewDidTouch))
        view.addGestureRecognizer(tapGesture)
        // scroll view for flexible height
        view.addSubview(scrollView)
        scrollView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        scrollView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard(inset: 16)
        
        // stackView
        scrollView.contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        stackView.addArrangedSubviews([
            sendButton.padding(UIEdgeInsets(x: 20, y: 0)),
            .spacer
        ])
        
        viewControllers = [
            SendTokenItemVC()
        ]
        
        view.layoutIfNeeded()
        
        // fix container's height
        let height = (viewControllers[currentPage] as! SendTokenItemVC).stackView.fittingHeight(targetWidth: stackView.frame.size.width)
        containerView.autoSetDimension(.height, toSize: height)
        
        // fix pageControl colors
        currentPageIndicatorTintColor = .textBlack
        pageIndicatorTintColor = .a4a4a4
        
        // error label
        view.addSubview(errorLabel)
        errorLabel.autoCenterInSuperview()
        errorLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
        errorLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
        
        errorLabel.isHidden = true
    }
    
    override func bind() {
        super.bind()
        viewModel.state
            .subscribe(onNext: { [weak self] state in
                switch state {
                case .initializing, .loading:
                    self?.showLoading()
                    self?.scrollView.isHidden = false
                    self?.errorLabel.isHidden = true
                case .loaded(let items):
                    self?.hideLoading()
                    self?.scrollView.isHidden = false
                    self?.errorLabel.isHidden = true
                    self?.viewControllers = items.map {item in
                        let vc: SendTokenItemVC
                        if let sendTokenVC = self?.viewControllers.first(where: {($0 as? SendTokenItemVC)?.wallet?.mintAddress == item.mintAddress}) as? SendTokenItemVC {
                            vc = sendTokenVC
                        } else {
                            vc = SendTokenItemVC()
                        }
                        vc.setUp(wallet: item)
                        return vc
                    }
                case .error(let error):
                    self?.hideLoading()
                    self?.scrollView.isHidden = true
                    self?.errorLabel.isHidden = false
                    #if DEBUG
                    self?.showError(error)
                    #endif
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func setUpContainerView() {
        stackView.addArrangedSubview(containerView)
    }
    
    override func setUpPageControl() {
        stackView.addArrangedSubview(pageControl)
    }
    
    @objc func viewDidTouch() {
        view.endEditing(true)
    }
}
