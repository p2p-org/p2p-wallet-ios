//
//  ChooseNewWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/11/2020.
//

import Foundation
import Action

class AddNewWalletVC: WalletsVC<AddNewWalletVC.Cell> {
    lazy var titleLabel = UILabel(text: L10n.addWallet, textSize: 17, weight: .semibold)
    lazy var closeButton = UIButton.close()
        .onTap(self, action: #selector(back))
    lazy var descriptionLabel = UILabel(textSize: 15, textColor: .secondary, numberOfLines: 0)
        .onTap(self, action: #selector(labelDescriptionDidTouch))
    
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
        let headerStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing, arrangedSubviews: [
                titleLabel,
                closeButton
            ]),
            descriptionLabel
        ])
        
        view.addSubview(headerStackView)
        headerStackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 25, left: 20, bottom: 0, right: 16), excludingEdge: .bottom)
        
        let separator = UIView.separator(height: 2, color: .vcBackground)
        view.addSubview(separator)
        separator.autoPinEdge(.top, to: .bottom, of: headerStackView, withOffset: 25)
        separator.autoPinEdge(toSuperviewEdge: .leading)
        separator.autoPinEdge(toSuperviewEdge: .trailing)
        
        // disable refreshing
        collectionView.refreshControl = nil
        collectionView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        collectionView.autoPinEdge(.top, to: .bottom, of: separator)
    }
    
    override func bind() {
        super.bind()
        let viewModel = self.viewModel as! ViewModel
        viewModel.feeVM.state
            .subscribe(onNext: {[weak self] state in
                guard let self = self else {return}
                switch state {
                case .initializing, .loading:
                    self.descriptionLabel.isUserInteractionEnabled = false
                    self.descriptionLabel.textColor = .secondary
                    self.descriptionLabel.text = L10n.gettingCreationFee + "..."
                case .loaded(let fee):
                    self.descriptionLabel.isUserInteractionEnabled = false
                    self.descriptionLabel.textColor = .secondary
                    self.descriptionLabel.text = L10n.AddATokenToYourWallet.thisWillCost + " " + fee.toString(maximumFractionDigits: 9) + " SOL"
                case .error(let error):
                    self.descriptionLabel.isUserInteractionEnabled = true
                    self.descriptionLabel.textColor = .red
                    self.descriptionLabel.text = L10n.ErrorWhenRetrievingCreationFee.tapToTryAgain + ": " + error.localizedDescription
                }
            })
            .disposed(by: disposeBag)
    }
    
    override var sections: [Section] {
        [Section(headerTitle: "", contentInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0))]
    }
    
    override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: Wallet) -> UICollectionViewCell {
        let cell = super.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        if let cell = cell as? Cell {
            cell.addButton.rx.action = self.createTokenAccountAction(newWallet: item)
            cell.copyToClipboardButton.rx.action = CocoaAction {
                UIApplication.shared.copyToClipboard(item.mintAddress)
                return .just(())
            }
        }
        return cell
    }
    
    @objc func labelDescriptionDidTouch() {
        let viewModel = self.viewModel as! ViewModel
        viewModel.feeVM.reload()
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
            
            return SolanaSDK.shared.createTokenAccount(mintAddress: newWallet.mintAddress, in: SolanaSDK.network)
                .do(
                    afterSuccess: { (signature, newPubkey) in
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

extension AddNewWalletVC: UIViewControllerTransitioningDelegate {
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

extension AddNewWalletVC {
    class ViewModel: ListViewModel<Wallet> {
        class FeeVM: BaseVM<Double> {
            func reload() {
                SolanaSDK.shared.getCreatingTokenAccountFee()
                    .subscribe(onSuccess: {[weak self] fee in
                        guard let strongSelf = self else {return}
                        let decimals = WalletsVM.ofCurrentUser.items.first(where: {$0.symbol == "SOL"})?.decimals ?? 9
                        strongSelf.data = Double(fee) * pow(Double(10), -Double(decimals))
                        strongSelf.state.accept(.loaded(strongSelf.data))
                    }, onError: {[weak self] error in
                        self?.state.accept(.error(error))
                    })
                    .disposed(by: disposeBag)
            }
        }
        
        let feeVM = FeeVM(initialData: 0)
        
        override func reload() {
            // get static data
            var wallets = SolanaSDK.Token.getSupportedTokens(network: SolanaSDK.network)?.compactMap {$0 != nil ? Wallet(programAccount: $0!) : nil} ?? []
            
            for i in 0..<wallets.count {
                if let price = PricesManager.bonfida.prices.value.first(where: {$0.from == wallets[i].symbol}) {
                    wallets[i].price = price
                }
            }
            
            data = wallets
            state.accept(.loaded(data))
            
            // fee
            feeVM.reload()
        }
        override func fetchNext() { /* do nothing */ }
    }
    
    class Cell: WalletCell {
        lazy var addButton = UIButton(width: 32, height: 32, backgroundColor: .ededed, cornerRadius: 16, label: "+", labelFont: .systemFont(ofSize: 20), textColor: UIColor.black.withAlphaComponent(0.5))
        lazy var symbolLabel = UILabel(text: "SER", textSize: 17, weight: .bold)
        lazy var mintAddressWrapper = UIStackView(axis: .horizontal, spacing: 35, alignment: .center, distribution: .fill, arrangedSubviews: [
            UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.mintAddress, textSize: 12, textColor: .secondary),
                mintAddressLabel
            ]),
            copyToClipboardButton
        ])
        lazy var mintAddressLabel = UILabel(textSize: 12)
        lazy var copyToClipboardButton: UIButton = {
            let button = UIButton(width: 32, height: 32, backgroundColor: .ededed, cornerRadius: 16)
            let image = UIImage.copyToClipboard
                .withRenderingMode(.alwaysTemplate)
            button.setImage(.copyToClipboard, for: .normal)
            button.tintColor = .textBlack
            button.contentEdgeInsets = .init(all: 6)
            return button
        }()
        
        override func commonInit() {
            super.commonInit()
            
            coinLogoImageView.removeAllConstraints()
            coinLogoImageView.autoSetDimensions(to: CGSize(width: 44, height: 44))
            coinLogoImageView.layer.cornerRadius = 22
            
            coinNameLabel.font = .systemFont(ofSize: 12, weight: .medium)
            coinNameLabel.textColor = .secondary
            
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
                    ]),
                    addButton
                ]),
                mintAddressWrapper
            ])
            
            stackView.constraintToSuperviewWithAttribute(.bottom)?.isActive = false
            let separator = UIView.separator(height: 2, color: .vcBackground)
            stackView.superview?.addSubview(separator)
            separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            separator.autoPinEdge(.top, to: .bottom, of: stackView, withOffset: 20)
        }
        
        override func setUp(with item: Wallet) {
            super.setUp(with: item)
            symbolLabel.text = item.symbol
            mintAddressWrapper.isHidden = !(item.isExpanded ?? false)
            mintAddressLabel.text = item.mintAddress
            contentView.backgroundColor = item.isExpanded == true ? .fafafa : .clear
        }
    }
}
