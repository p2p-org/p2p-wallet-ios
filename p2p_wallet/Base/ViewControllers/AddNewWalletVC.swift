//
//  ChooseNewWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/11/2020.
//

import Foundation
import Action
import RxSwift

class AddNewWalletVC: WLModalWrapperVC {
    init() {
        super.init(wrapped: _AddNewWalletVC())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.addArrangedSubviews([
            UILabel(text: L10n.addWallet, textSize: 17, weight: .semibold)
                .padding(.init(x: 20, y: 0)),
            UIButton(label: L10n.close, labelFont: .systemFont(ofSize: 17, weight: .medium), textColor: .h5887ff)
                .onTap(self, action: #selector(back))
                .padding(.init(x: 20, y: 0))
        ])
        let separator = UIView.separator(height: 1, color: .separator)
        containerView.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }
}

class _AddNewWalletVC: WalletsVC {
    init() {
        let viewModel = ViewModel()
        super.init(viewModel: viewModel)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        
        // disable refreshing
        collectionView.refreshControl = nil
    }
    
    override var sections: [Section] {
        [
            Section(
                cellType: Cell.self,
                contentInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            )
        ]
    }
    
    override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: Wallet) -> UICollectionViewCell {
        let cell = super.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        if let cell = cell as? Cell, indexPath.row < self.viewModel.data.count {
            let wallet = self.viewModel.data[indexPath.row]
            
            cell.viewInBlockchainExplorerButton.rx.action = CocoaAction {_ in
                self.showWebsite(url: "https://explorer.solana.com/address/\(wallet.mintAddress)")
                return .just(())
            }
            
            cell.createWalletAction = createTokenAccountAction(newWallet: wallet)
            
            cell.setUp(feeVM: (viewModel as! ViewModel).feeVM)
        }
        return cell
    }
    
    func createTokenAccountAction(newWallet: Wallet) -> CocoaAction {
        CocoaAction {
            let viewModel = self.viewModel as! ViewModel
            
            if viewModel.feeVM.data > (WalletsVM.ofCurrentUser.solWallet?.amount ?? 0)
            {
                self.showAlert(title: L10n.error.uppercaseFirst, message: L10n.insufficientFunds)
                return .just(())
            }
            
            let transactionVC = self.presentProcessTransactionVC()
            
            return SolanaSDK.shared.createTokenAccount(mintAddress: newWallet.mintAddress, in: Defaults.network.cluster)
                .do(
                    afterSuccess: { (signature, newPubkey) in
                        // remove suggestion from the list
                        self.viewModel.removeItem(where: {$0.mintAddress == newWallet.mintAddress})
                        
                        // process transaction
                        transactionVC.signature = signature
                        transactionVC.viewInExplorerButton.rx.action = CocoaAction {
                            transactionVC.dismiss(animated: true) {
                                let vc = self.presentingViewController
                                self.dismiss(animated: true) {
                                    vc?.showWebsite(url: "https://explorer.solana.com/tx/" + signature)
                                }
                            }
                            return .just(())
                        }
                        transactionVC.goBackToWalletButton.rx.action = CocoaAction {
                            transactionVC.dismiss(animated: true, completion: nil)
                            return .just(())
                        }
                        
                        var newWallet = newWallet
                        newWallet.pubkey = newPubkey
                        newWallet.isProcessing = true
                        let transaction = Transaction(
                            signatureInfo: .init(signature: signature),
                            type: .createAccount,
                            amount: -viewModel.feeVM.data,
                            symbol: "SOL",
                            status: .processing,
                            newWallet: newWallet
                        )
                        TransactionsManager.shared.process(transaction)
                    },
                    afterError: { (error) in
                        transactionVC.dismiss(animated: true) {
                            self.showError(error)
                        }
                    }
                )
                .map {_ in ()}
                .asObservable()
        }
    }
    
    override func itemDidSelect(_ item: Wallet) {
        viewModel.updateItem(where: {item.mintAddress == $0.mintAddress}, transform: {
            var wallet = $0
            wallet.isExpanded = !(wallet.isExpanded ?? false)
            return wallet
        })
    }
}

extension _AddNewWalletVC: UIViewControllerTransitioningDelegate {
    class PresentationController: CustomHeightPresentationController {
        override func containerViewDidLayoutSubviews() {
            super.containerViewDidLayoutSubviews()
            presentedView?.roundCorners([.topLeft, .topRight], radius: 20)
        }
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(height: {
            if UIDevice.current.userInterfaceIdiom == .phone, UIDevice.current.orientation == .landscapeLeft ||
                UIDevice.current.orientation == .landscapeRight
            {
                return UIScreen.main.bounds.height
            }
            return UIScreen.main.bounds.height - 85.adaptiveHeight
        }, presentedViewController: presented, presenting: presenting)
    }
}

extension _AddNewWalletVC {
    class ViewModel: ListViewModel<Wallet> {
        class FeeVM: BaseVM<Double> {
            override var request: Single<Double> {
                SolanaSDK.shared.getCreatingTokenAccountFee()
                    .map {
                        let decimals = WalletsVM.ofCurrentUser.items.first(where: {$0.symbol == "SOL"})?.decimals ?? 9
                        return Double($0) * pow(Double(10), -Double(decimals))
                    }
            }
        }
        
        let feeVM = FeeVM(initialData: 0)
        
        override func reload() {
            // get static data
            var wallets = SolanaSDK.Token.getSupportedTokens(network: Defaults.network.cluster)?.compactMap {$0 != nil ? Wallet(programAccount: $0!) : nil} ?? []
            
            for i in 0..<wallets.count {
                if let price = PricesManager.shared.currentPrice(for: wallets[i].symbol)
                {
                    wallets[i].price = price
                }
            }
            
            data = wallets
                .filter { newWallet in
                    !WalletsVM.ofCurrentUser.data.contains(where: {$0.mintAddress == newWallet.mintAddress})
                }
            state.accept(.loaded(data))
            
            // fee
            feeVM.reload()
        }
        override func fetchNext() { /* do nothing */ }
    }
    
    class Cell: WalletCell {
        private let disposeBag = DisposeBag()
        lazy var symbolLabel = UILabel(text: "SER", textSize: 17, weight: .bold)
        lazy var detailView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill, arrangedSubviews: [
            .separator(height: 1, color: .separator),
            UILabel(text: L10n.mintAddress, textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 0),
            mintAddressLabel,
            .separator(height: 1, color: .separator),
            viewInBlockchainExplorerButton,
            UIStackView(axis: .vertical, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.addWallet, textSize: 15, weight: .semibold, textColor: .white, textAlignment: .center),
                feeLabel
            ])
                .padding(.init(x: 16, y: 10), backgroundColor: .h5887ff, cornerRadius: 12)
                .onTap(self, action: #selector(buttonCreateWalletDidTouch))
        ], customSpacing: [20, 5, 20, 20, 20])
        lazy var mintAddressLabel = UILabel(textSize: 15, weight: .semibold, numberOfLines: 0)
        lazy var viewInBlockchainExplorerButton = UIButton(label: L10n.viewInBlockchainExplorer, labelFont: .systemFont(ofSize: 15, weight: .semibold), textColor: .a3a5ba)
        lazy var feeLabel = LazyLabel<Double>(textSize: 13, textColor: .f6f6f8, textAlignment: .center)
        
        var createWalletAction: CocoaAction?
        
        override func commonInit() {
            super.commonInit()
            
            coinLogoImageView.removeAllConstraints()
            coinLogoImageView.autoSetDimensions(to: CGSize(width: 44, height: 44))
            coinLogoImageView.layer.cornerRadius = 22
            
            coinNameLabel.font = .systemFont(ofSize: 12, weight: .medium)
            coinNameLabel.textColor = .textSecondary
            
            coinPriceLabel.font = .systemFont(ofSize: 17, weight: .bold)
            
            coinChangeLabel.font = .systemFont(ofSize: 12, weight: .medium)
            
            stackView.axis = .vertical
            stackView.alignment = .fill
            stackView.distribution = .fill
            stackView.addArrangedSubviews([
                UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                    coinLogoImageView,
                    UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
                        UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                            symbolLabel,
                            coinPriceLabel
                        ]),
                        UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                            coinNameLabel,
                            coinChangeLabel
                        ])
                    ])
                ]),
                detailView
            ], withCustomSpacings: [16])
            
            stackView.constraintToSuperviewWithAttribute(.bottom)?.isActive = false
            let separator = UIView.separator(height: 2, color: .vcBackground)
            stackView.superview?.addSubview(separator)
            separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            separator.autoPinEdge(.top, to: .bottom, of: stackView, withOffset: 20)
            
            stackView.constraintToSuperviewWithAttribute(.top)?.constant = 10
            stackView.constraintToSuperviewWithAttribute(.leading)?.constant = 20
            stackView.constraintToSuperviewWithAttribute(.trailing)?.constant = -20
        }
        
        override func setUp(with item: Wallet) {
            super.setUp(with: item)
            symbolLabel.text = item.symbol
            detailView.isHidden = !(item.isExpanded ?? false)
            mintAddressLabel.text = item.mintAddress
            contentView.backgroundColor = item.isExpanded == true ? .f6f6f8 : .clear
        }
        
        func setUp(feeVM: ViewModel.FeeVM) {
            if feeLabel.viewModel == nil {
                feeLabel
                    .subscribed(to: feeVM) {
                        L10n.willCost + " " + $0.toString(maximumFractionDigits: 9) + " SOL"
                    }
                    .disposed(by: disposeBag)
            }
            
        }
        
        @objc func buttonCreateWalletDidTouch() {
            createWalletAction?.execute()
        }
    }
}
