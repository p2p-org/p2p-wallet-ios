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
    lazy var searchBar: BESearchBar = {
        let searchBar = BESearchBar(fixedHeight: 36, cornerRadius: 12)
        searchBar.textFieldBgColor = .lightGrayBackground
        searchBar.magnifyingIconSize = 24
        searchBar.magnifyingIconImageView.image = .search
        searchBar.magnifyingIconImageView.tintColor = .textBlack
        searchBar.leftViewWidth = 24+10+10
        searchBar.placeholder = L10n.searchToken
        searchBar.delegate = self
        searchBar.cancelButton.setTitleColor(.h5887ff, for: .normal)
        searchBar.setUpTextField(autocorrectionType: .no, autocapitalizationType: UITextAutocapitalizationType.none, spellCheckingType: .no)
        return searchBar
    }()
    
    init() {
        super.init(wrapped: _AddNewWalletVC())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.addToken, textSize: 17, weight: .semibold)
                    .padding(.init(x: 20, y: 0)),
                UIButton(label: L10n.close, labelFont: .systemFont(ofSize: 17, weight: .medium), textColor: .h5887ff)
                    .onTap(self, action: #selector(back))
                    .padding(.init(x: 20, y: 0))
            ]),
            BEStackViewSpacing.defaultPadding,
            UIView.separator(height: 1, color: .separator),
            BEStackViewSpacing.defaultPadding,
            searchBar
                .padding(.init(x: .defaultPadding, y: 0))
        ])
        
    }
}

extension AddNewWalletVC: BESearchBarDelegate {
    func beSearchBar(_ searchBar: BESearchBar, searchWithKeyword keyword: String) {
        let vm = (self.vc as! _AddNewWalletVC).viewModel as! _AddNewWalletVC.ViewModel
        vm.offlineSearch(query: keyword)
    }
    
    func beSearchBarDidBeginSearching(_ searchBar: BESearchBar) {
        
    }
    
    func beSearchBarDidEndSearching(_ searchBar: BESearchBar) {
        
    }
    
    func beSearchBarDidCancelSearching(_ searchBar: BESearchBar) {
        
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
        collectionView.keyboardDismissMode = .onDrag
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
        if let cell = cell as? Cell, let wallet = itemAtIndexPath(indexPath)
        {
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
            
            // catching error
            if viewModel.feeVM.data > (WalletsVM.ofCurrentUser.solWallet?.amount ?? 0)
            {
                viewModel.updateItem(where: {$0.mintAddress == newWallet.mintAddress}, transform: {
                    var wallet = $0
                    wallet.isBeingCreated = nil
                    wallet.creatingError = L10n.insufficientFunds
                    return wallet
                })
                return .just(())
            }
            
            // remove existing error
            viewModel.updateItem(where: {$0.mintAddress == newWallet.mintAddress}, transform: {
                var wallet = $0
                wallet.isBeingCreated = true
                wallet.creatingError = nil
                return wallet
            })
            
            // request
            return SolanaSDK.shared.createTokenAccount(mintAddress: newWallet.mintAddress)
//            return Single<(String, String)>.just(("", "")).delay(.seconds(5), scheduler: MainScheduler.instance)
//                .map {_ -> (String, String) in
//                    throw SolanaSDK.Error.other("example")
//                }
                .do(
                    afterSuccess: { (signature, newPubkey) in
                        // remove suggestion from the list
                        self.viewModel.removeItem(where: {$0.mintAddress == newWallet.mintAddress})
                        
                        // cancel search if search result is empty
                        if self.viewModel.searchResult?.isEmpty == true
                        {
                            (self.parent as? AddNewWalletVC)?.searchBar.clear()
                        }
                        
                        // process transaction
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
                        
                        // present wallet
                        self.present(WalletDetailVC(wallet: newWallet), animated: true, completion: nil)
                    },
                    afterError: { (error) in
                        viewModel.updateItem(where: {$0.mintAddress == newWallet.mintAddress}, transform: {
                            var wallet = $0
                            wallet.isBeingCreated = nil
                            wallet.creatingError = error.localizedDescription
                            return wallet
                        })
                    }
                )
                .map {_ in ()}
                .asObservable()
        }
    }
    
    override func itemDidSelect(_ item: Wallet) {
        parent?.view.endEditing(true)
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
            var wallets = SolanaSDK.Token.getSupportedTokens(network: Defaults.network)?.compactMap {$0 != nil ? Wallet(programAccount: $0!) : nil} ?? []
            
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
        
        override func offlineSearchPredicate(item: Wallet, lowercasedQuery query: String) -> Bool {
            item.name.lowercased().contains(query) ||
            item.symbol.lowercased().contains(query)
        }
    }
    
    class Cell: WalletCell {
        private let disposeBag = DisposeBag()
        lazy var symbolLabel = UILabel(text: "SER", textSize: 17, weight: .bold)
        
        lazy var mintAddressLabel = UILabel(textSize: 15, weight: .semibold, numberOfLines: 0)
        lazy var viewInBlockchainExplorerButton = UIButton(label: L10n.viewInBlockchainExplorer, labelFont: .systemFont(ofSize: 15, weight: .semibold), textColor: .a3a5ba)
        
        lazy var buttonAddTokenLabel = UILabel(text: L10n.addToken, textSize: 15, weight: .semibold, textColor: .white, textAlignment: .center)
        
        lazy var feeLabel: LazyLabel<Double> = {
            let label = LazyLabel<Double>(textSize: 13, textColor: UIColor.white.withAlphaComponent(0.5), textAlignment: .center)
            label.isUserInteractionEnabled = false
            return label
        }()
        
        lazy var buttonAddToken: WLLoadingView = {
            let loadingView = WLLoadingView(height: 56, backgroundColor: .h5887ff, cornerRadius: 12)
            let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
                buttonAddTokenLabel,
                feeLabel
            ])
            loadingView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 16, y: 10))
            return loadingView
        }()
        
        lazy var errorLabel = UILabel(textSize: 13, textColor: .red, numberOfLines: 0, textAlignment: .center)
        
        lazy var detailView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill, arrangedSubviews: [
            UIView.separator(height: 1, color: .separator),
            BEStackViewSpacing(20),
            UILabel(text: L10n.mintAddress, textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 0),
            BEStackViewSpacing(5),
            mintAddressLabel,
            BEStackViewSpacing(20),
            UIView.separator(height: 1, color: .separator),
            BEStackViewSpacing(20),
            viewInBlockchainExplorerButton,
            BEStackViewSpacing(20),
            buttonAddToken
                .onTap(self, action: #selector(buttonCreateWalletDidTouch)),
            BEStackViewSpacing(16),
            errorLabel
        ])
        
        var createWalletAction: CocoaAction?
        
        override func commonInit() {
            super.commonInit()
            
            coinLogoImageView.widthConstraint?.constant = 44
            coinLogoImageView.heightConstraint?.constant = 44
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
                BEStackViewSpacing(16),
                detailView
            ])
            
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
            
            if item.isBeingCreated == true {
                buttonAddToken.setUp(loading: true)
                buttonAddTokenLabel.text = L10n.addingTokenToYourWallet
                feeLabel.isHidden = true
            } else {
                buttonAddToken.setUp(loading: false)
                buttonAddTokenLabel.text = L10n.addToken
                feeLabel.isHidden = false
            }
            
            if let error = item.creatingError {
                errorLabel.isHidden = false
                errorLabel.text = L10n.WeCouldnTAddATokenToYourWallet.checkYourInternetConnectionAndTryAgain
            } else {
                errorLabel.isHidden = true
            }
        }
        
        func setUp(feeVM: ViewModel.FeeVM) {
            if feeLabel.viewModel == nil {
                feeLabel
                    .subscribed(to: feeVM) {
                        L10n.willCost + " " + $0.toString(maximumFractionDigits: 9) + " SOL"
                    }
                    .disposed(by: disposeBag)
                feeLabel.isUserInteractionEnabled = false
            }
            
        }
        
        @objc func buttonCreateWalletDidTouch() {
            if buttonAddToken.isLoading {
                return
            }
            createWalletAction?.execute()
        }
    }
}
