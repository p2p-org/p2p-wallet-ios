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
    
    init(selectedWalletPubkey: String? = nil, destinationAddress: String? = nil) {
        let vc = _SendTokenVC(selectedWalletPubkey: selectedWalletPubkey, destinationAddress: destinationAddress)
        super.init(wrapped: vc)
    }
    
    override func setUp() {
        super.setUp()
        addHeader(title: L10n.send, image: .walletSend)
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
    let initialSelectedWalletPubkey: String?
    let initialDestinationAddress: String?
    
    init(selectedWalletPubkey: String? = nil, destinationAddress: String? = nil) {
        initialSelectedWalletPubkey = selectedWalletPubkey
        initialDestinationAddress = destinationAddress
        super.init()
    }
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        
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
            sendButton,
            .spacer
        ])
        
        // placeholder vc
        viewControllers = WalletsVM.ofCurrentUser.data
            .map {self.sendTokenItemVCForItem($0)}
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
        
        // set up initial data
        if let pubkey = initialSelectedWalletPubkey,
           let index = WalletsVM.ofCurrentUser.data.firstIndex(where: {$0.pubkey == pubkey})
        {
            moveToPage(index)
        }

        // if address was passed
        if let address = initialDestinationAddress,
            let textView = (viewControllers.first as? SendTokenItemVC)?.addressTextView
        {
            textView.text = address
        }
        
        // enable textfield
        (viewControllers[currentPage] as! SendTokenItemVC)
            .amountTextField.becomeFirstResponder()
    }
    
    override func bind() {
        super.bind()
        let vcs = viewControllers.map {$0 as! SendTokenItemVC}.enumerated()
        
        Observable.merge(vcs.map { (index, vc) in
            vc.dataDidChange
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
//        stackView.addArrangedSubview(pageControl)
    }
    
    @objc func viewDidTouch() {
        view.endEditing(true)
    }
    
    @objc func buttonSendDidTouch() {
        guard currentPage < viewControllers.count,
              let vc = viewControllers[currentPage] as? SendTokenItemVC,
              let sender = vc.wallet?.pubkey,
              let receiver = vc.addressTextView.text,
              let price = vc.wallet?.priceInUSD,
              price > 0
        else {
            return
        }
        
        var amount = vc.amountTextField.value
        if vc.isUSDMode.value,
           let price = vc.wallet?.priceInUSD,
           price > 0
        {
            amount = amount / price
        }
        
        let transactionVC = presentProcessTransactionVC()
        
        // prepare amount
        let lamport = UInt64(amount * pow(10, Double(vc.wallet?.decimals ?? 0)))
        
        SolanaSDK.shared.sendTokens(from: sender, to: receiver, amount: lamport)
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
    
    // MARK: - Helpers
    private func sendTokenItemVCForItem(_ item: Wallet) -> SendTokenItemVC {
        let vc = SendTokenItemVC()
        vc.chooseWalletAction = CocoaAction {
            let vc = ChooseWalletVC()
            vc.completion = {wallet in
                guard let index = WalletsVM.ofCurrentUser.data.firstIndex(where: {$0.pubkey == wallet.pubkey}) else {return}
                vc.back()
                self.moveToPage(index)
            }
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
        vc.setUp(wallet: item)
        return vc
    }
}

extension _SendTokenVC: BEPagesVCDelegate {
    func bePagesVC(_ pagesVC: BEPagesVC, currentPageDidChangeTo currentPage: Int) {
        // trigger observable
        (viewControllers[currentPage] as! SendTokenItemVC).amountTextField.sendActions(for: .valueChanged)
    }
}
