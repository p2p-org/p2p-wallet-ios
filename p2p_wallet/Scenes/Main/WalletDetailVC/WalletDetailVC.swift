//
//  WalletDetailVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import Action

protocol WalletDetailScenesFactory {
    func makeSendTokenViewController(activeWallet: Wallet?, destinationAddress: String?) -> WLModalWrapperVC
    func makeSwapTokenViewController(fromWallet: Wallet?) -> SwapTokenViewController
}

class WalletDetailVC: WLModalWrapperVC {
    override var padding: UIEdgeInsets {UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)}
    
    let solanaSDK: SolanaSDK
    let walletsVM: WalletsVM
    let scenesFactory: WalletDetailScenesFactory
    let wallet: Wallet
    lazy var walletNameTextField: UITextField = {
        let tf = UITextField(font: .systemFont(ofSize: 19, weight: .semibold), placeholder: "A", autocorrectionType: .no)
        tf.isUserInteractionEnabled = false
        tf.text = wallet.name
        return tf
    }()
    
    lazy var tabBar = TabBar(cornerRadius: 20, contentInset: .init(x: 20, y: 10))
    
    // MARK: - Initializer
    init(solanaSDK: SolanaSDK, walletsVM: WalletsVM, wallet: Wallet, scenesFactory: WalletDetailScenesFactory) {
        self.solanaSDK = solanaSDK
        self.walletsVM = walletsVM
        self.wallet = wallet
        self.scenesFactory = scenesFactory
        let viewModel = _WalletDetailVC.ViewModel(solanaSDK: solanaSDK, walletsVM: walletsVM, wallet: wallet)
        super.init(wrapped: _WalletDetailVC(viewModel: viewModel))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.bringSubviewToFront(tabBar)
        // update prices
        PricesManager.shared.fetchCurrentPrices()
    }
    
    override func setUp() {
        super.setUp()
        
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
                CoinLogoImageView(width: 35, height: 35, cornerRadius: 12)
                    .with(wallet: wallet),
                BEStackViewSpacing(16),
                walletNameTextField
                    .withContentHuggingPriority(.required, for: .horizontal),
                BEStackViewSpacing(0),
                UILabel(text: " \(L10n.walletRename)", textSize: 19, weight: .semibold),
                BEStackViewSpacing(10),
                UIImageView(width: 16, height: 18, image: .buttonEdit, tintColor: .a3a5ba)
                    .onTap(self, action: #selector(buttonEditDidTouch))
            ])
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            UIView.separator(height: 2, color: .separator),
            BEStackViewSpacing(0)
        ])
        
        // tabBar
        view.addSubview(tabBar)
        tabBar.backgroundColor = .h202020
        tabBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        
        tabBar.stackView.addArrangedSubviews([
//            UIImageView(width: 24, height: 24, image: .walletAdd, tintColor: .white)
//                .padding(.init(all: 16)),
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
    
    override func bind() {
        super.bind()
        walletNameTextField.rx.text.orEmpty
            .skip(1)
            .map {$0.trimmingCharacters(in: .whitespacesAndNewlines)}
            .distinctUntilChanged()
            .subscribe(onNext: {
                var newName = $0
                if $0.isEmpty {
                    // fall back to wallet name
                    newName = self.wallet.name
                }
                self.walletsVM.updateWallet(self.wallet, withName: newName)
            })
            .disposed(by: disposeBag)
        
        walletNameTextField.delegate = self
    }
    
    // MARK: - Actions
    override func dismissKeyboard() {
        super.dismissKeyboard()
        walletNameTextField.isUserInteractionEnabled = false
    }
    
    @objc func buttonEditDidTouch() {
        walletNameTextField.isUserInteractionEnabled.toggle()
        if walletNameTextField.isUserInteractionEnabled {
            walletNameTextField.becomeFirstResponder()
        }
    }
    
    @objc func buttonSendDidTouch() {
        let vc = scenesFactory.makeSendTokenViewController(activeWallet: wallet, destinationAddress: nil)
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func buttonReceiveDidTouch() {
        let vc = ReceiveTokenVC(wallets: [self.wallet])
        self.show(vc, sender: nil)
    }
    
    @objc func buttonSwapDidTouch() {
        let vc = scenesFactory.makeSwapTokenViewController(fromWallet: wallet)
        self.show(vc, sender: nil)
    }
}

extension WalletDetailVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
}

private class _WalletDetailVC: CollectionVC<Transaction> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .embeded }
    var graphVM: WalletGraphVM { (viewModel as! ViewModel).graphVM }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        let vm = viewModel as! ViewModel
        title = vm.wallet.name
        view.backgroundColor = .vcBackground
        
        collectionView.contentInset = collectionView.contentInset.modifying(dBottom: 71)
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [Section(
            header: Section.Header(
                viewClass: WDVCSectionHeaderView.self,
                title: L10n.activities
            ),
            cellType: TransactionCell.self,
            interGroupSpacing: 2,
            itemHeight: .absolute(71)
        )]
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        let vm = viewModel as! ViewModel
        if indexPath.section == 0 {
            let header = header as! WDVCSectionHeaderView
            header.setUp(wallet: vm.wallet)
            header.lineChartView
                .subscribed(to: graphVM)
                .disposed(by: disposeBag)
            header.chartPicker.delegate = self
            header.scanQrCodeAction = CocoaAction {
                let vc = ReceiveTokenVC(wallets: [vm.wallet])
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
        
        override init(solanaSDK: SolanaSDK, walletsVM: WalletsVM, wallet: Wallet) {
            graphVM = WalletGraphVM(wallet: wallet)
            super.init(solanaSDK: solanaSDK, walletsVM: walletsVM, wallet: wallet)
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
