//
//  WalletDetailVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import DiffableDataSources
import Action

class WalletDetailVC: WLModalVC {
    override var padding: UIEdgeInsets {UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)}
    
    let wallet: Wallet
    fileprivate lazy var vc = _WalletDetailVC(wallet: wallet)
    lazy var walletNameTextField: UITextField = {
        let tf = UITextField(font: .systemFont(ofSize: 19, weight: .semibold), placeholder: L10n.walletName, autocorrectionType: .no)
        tf.isUserInteractionEnabled = false
        tf.text = wallet.name
        return tf
    }()
    
    lazy var tabBar = TabBar(cornerRadius: 20, contentInset: .init(x: 20, y: 10))
    
    // MARK: - Initializer
    init(wallet: Wallet) {
        self.wallet = wallet
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        
        stackView.addArrangedSubviews([
            UIView.row([
                UIImageView(width: 35, height: 35, cornerRadius: 12)
                    .with(urlString: wallet.icon),
                walletNameTextField,
                UIImageView(width: 16, height: 18, image: .buttonEdit, tintColor: .a3a5ba)
                    .onTap(self, action: #selector(buttonEditDidTouch))
            ])
                .with(spacing: 16, distribution: .fill)
                .padding(.init(x: 20, y: 0)),
            .separator(height: 2, color: .separator)
        ], withCustomSpacings: [20, 0])
        
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(vc)
        // collectionView(didSelectItemAt) would not be called if
        // we add vc.view inside stackView or containerView, so I
        // add vc.view directly into `view`
        view.addSubview(vc.view)
        containerView.constraintToSuperviewWithAttribute(.bottom)?
            .isActive = false
        vc.view.autoPinEdge(.top, to: .bottom, of: containerView)
        vc.view.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        vc.didMove(toParent: self)
        
        // tabBar
        view.addSubview(tabBar)
        tabBar.backgroundColor = .h202020
        tabBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        
        tabBar.stackView.addArrangedSubviews([
            UIImageView(width: 24, height: 24, image: .walletAdd, tintColor: .white)
                .padding(.init(all: 16)),
            UIImageView(width: 24, height: 24, image: .walletReceive, tintColor: .white)
                .padding(.init(all: 16))
                .onTap(self, action: #selector(buttonReceiveDidTouch)),
            UIImageView(width: 24, height: 24, image: .walletSend, tintColor: .white)
                .padding(.init(all: 16))
                .onTap(self, action: #selector(buttonSendDidTouch)),
            UIImageView(width: 24, height: 24, image: .walletSwap, tintColor: .white)
                .padding(.init(all: 16))
                .onTap(self, action: #selector(buttonSwapDidTouch))
        ])
    }
    
    @objc func buttonEditDidTouch() {
        walletNameTextField.isUserInteractionEnabled.toggle()
        if walletNameTextField.isUserInteractionEnabled {
            walletNameTextField.becomeFirstResponder()
        }
    }
    
    @objc func buttonSendDidTouch() {
        let vc = SendTokenVC(wallets: WalletsVM.ofCurrentUser.data, initialSymbol: wallet.symbol)
        self.show(vc, sender: nil)
    }
    
    @objc func buttonReceiveDidTouch() {
        let vc = ReceiveTokenVC(filteredSymbols: [self.wallet.symbol])
        self.show(vc, sender: nil)
    }
    
    @objc func buttonSwapDidTouch() {
        // TODO: - Swap
        let vc = SwapTokenVC(wallets: WalletsVM.ofCurrentUser.data)
        self.show(vc, sender: nil)
    }
}

private class _WalletDetailVC: CollectionVC<Transaction, TransactionCell> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .embeded }
    let wallet: Wallet
    var graphVM: WalletGraphVM { (viewModel as! ViewModel).graphVM }
    
    // MARK: - Initializer
    init(wallet: Wallet) {
        self.wallet = wallet
        super.init(viewModel: ViewModel(wallet: wallet))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        title = wallet.name
        view.backgroundColor = .vcBackground
        
        collectionView.contentInset = collectionView.contentInset.modifying(dBottom: 71)
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [Section(
            headerViewClass: WDVCSectionHeaderView.self,
            headerTitle: L10n.activities,
            interGroupSpacing: 2,
            itemHeight: .absolute(71)
        )]
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        if indexPath.section == 0 {
            let header = header as! WDVCSectionHeaderView
            header.setUp(wallet: wallet)
            header.lineChartView
                .subscribed(to: graphVM)
                .disposed(by: disposeBag)
            header.chartPicker.delegate = self
            header.scanQrCodeAction = CocoaAction {
                let vc = ReceiveTokenVC(filteredSymbols: [self.wallet.symbol])
                self.present(vc, animated: true, completion: nil)
                return .just(())
            }
        }
        return header
    }
    
    override func itemDidSelect(_ item: Transaction) {
        let vc = TransactionInfoVC(transaction: item)
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    func createButton(title: String) -> UIView {
        let view = UIView(height: 56, backgroundColor: .textBlack)
        let label = UILabel(text: title, textSize: 15.adaptiveWidth, weight: .semibold, textColor: .textWhite, numberOfLines: 0, textAlignment: .center)
        view.addSubview(label)
        label.autoPinEdge(toSuperviewEdge: .top)
        label.autoPinEdge(toSuperviewEdge: .bottom)
        label.autoPinEdge(toSuperviewEdge: .leading, withInset: 16.adaptiveWidth)
        label.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16.adaptiveWidth)
        return view
    }
}

extension _WalletDetailVC {
    class ViewModel: WalletTransactionsVM {
        let graphVM: WalletGraphVM
        
        override init(wallet: Wallet) {
            graphVM = WalletGraphVM(wallet: wallet)
            super.init(wallet: wallet)
        }
        
        override func reload() {
            graphVM.reload()
            super.reload()
        }
    }
}

extension _WalletDetailVC: HorizontalPickerDelegate {
    func picker(_ picker: HorizontalPicker, didSelectOptionAtIndex index: Int) {
        guard index < Period.allCases.count else {return}
        graphVM.period = Period.allCases[index]
        graphVM.reload()
    }
}
