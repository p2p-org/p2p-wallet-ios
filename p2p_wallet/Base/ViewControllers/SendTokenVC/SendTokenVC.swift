//
//  SendTokenVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/12/20.
//

import Foundation
import RxSwift
import Action

class SendTokenVC: WLModalWrapperVC {
    override var padding: UIEdgeInsets {super.padding.modifying(dLeft: .defaultPadding, dRight: .defaultPadding)}
    
    init(wallets: [Wallet], address: String? = nil, initialSymbol: String? = nil) {
        let vc = _SendTokenVC(wallets: wallets, address: address, initialSymbol: initialSymbol)
        super.init(wrapped: vc)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.addArrangedSubviews([
            UIImageView(width: 24, height: 24, image: .walletSend, tintColor: .white)
                .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12),
            UILabel(text: L10n.send, textSize: 17, weight: .semibold)
        ])
        
        let separator = UIView.separator(height: 1, color: .separator)
        containerView.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }
}

class _SendTokenVC: BEPagesVC, LoadableView {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .normal(backgroundColor: .vcBackground)
    }
    var loadingViews: [UIView] { [containerView, sendButton] }
    
    lazy var scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: UIEdgeInsets(top: .defaultPadding, left: .defaultPadding, bottom: 0, right: .defaultPadding))
    lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
    lazy var sendButton = WLButton.stepButton(type: .blue, label: L10n.sendNow)
        .onTap(self, action: #selector(buttonSendDidTouch))
    
    lazy var errorLabel = UILabel(textSize: 17, weight: .semibold, textColor: .textBlack, numberOfLines: 0, textAlignment: .center)
    
    let disposeBag = DisposeBag()
    var wallets: [Wallet]
    var initialAddress: String?
    var initialSymbol: String?
    
    init(wallets: [Wallet], address: String? = nil, initialSymbol: String? = nil) {
        self.wallets = wallets
            .filter {
                $0.symbol == "SOL" || $0.amount > 0
            }
        self.initialAddress = address
        self.initialSymbol = initialSymbol
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .background
        
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
        
        viewControllers = wallets
            .map {item in
                let vc = SendTokenItemVC()
                vc.chooseWalletAction = CocoaAction {
                    let vc = ChooseWalletVC()
                    vc.completion = {wallet in
                        guard let index = self.wallets.firstIndex(where: {$0.mintAddress == wallet.mintAddress}) else {return}
                        self.moveToPage(index)
                        vc.back()
                    }
                    self.present(vc, animated: true, completion: nil)
                    return .just(())
                }
                vc.setUp(wallet: item)
                return vc
            }
        
        if let symbol = initialSymbol,
           let index = wallets.firstIndex(where: {$0.symbol == symbol})
        {
            moveToPage(index)
        }
        
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
        
        // delegate
        self.delegate = self
        
        // if address was passed
        if let address = initialAddress,
            let textView = (viewControllers.first as? SendTokenItemVC)?.addressTextView
        {
            textView.text = address
        }
    }
    
    override func bind() {
        super.bind()
        let vcs = viewControllers.map {$0 as! SendTokenItemVC}.enumerated()
        
        Observable.merge(vcs.map { (index, vc) in
            vc.dataObservable
                .map {_ in vc.isDataValid}
                .filter {_ in index == self.currentPage}
        })
            .asDriver(onErrorJustReturn: false)
            .drive(sendButton.rx.isEnabled)
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
    
    @objc func buttonSendDidTouch() {
        guard currentPage < viewControllers.count,
              let vc = viewControllers[currentPage] as? SendTokenItemVC,
              let sender = vc.wallet?.pubkey,
              let receiver = vc.addressTextView.text,
              let amount = vc.amountTextField.text?.double
        else {
            return
        }
        
        let transactionVC = presentProcessTransactionVC()
        
        // prepare amount
        let amountToSend = amount * pow(10, Double(vc.wallet?.decimals ?? 0))
        
        SolanaSDK.shared.sendTokens(from: sender, to: receiver, amount: Int64(amountToSend))
            .subscribe(onSuccess: { signature in
                transactionVC.signature = signature
                transactionVC.viewInExplorerButton.rx.action = CocoaAction {
                    transactionVC.dismiss(animated: true) {
                        let nc = self.navigationController
                        self.back()
                        nc?.showWebsite(url: "https://explorer.solana.com/tx/" + signature)
                    }
                    
                    return .just(())
                }
                transactionVC.goBackToWalletButton.rx.action = CocoaAction {
                    transactionVC.dismiss(animated: true) {
                        self.back()
                    }
                    return .just(())
                }
                
                let transaction = Transaction(
                    signatureInfo: .init(signature: signature),
                    type: .send,
                    amount: -amount,
                    symbol: vc.wallet?.symbol ?? "",
                    status: .processing
                )
                TransactionsManager.shared.process(transaction)
            }, onError: {error in
                transactionVC.dismiss(animated: true) {
                    self.showError(error)
                }
            })
            .disposed(by: disposeBag)
    }
}

extension _SendTokenVC: BEPagesVCDelegate {
    func bePagesVC(_ pagesVC: BEPagesVC, currentPageDidChangeTo currentPage: Int) {
        // trigger observable
        (viewControllers[currentPage] as! SendTokenItemVC).amountTextField.sendActions(for: .valueChanged)
    }
}
