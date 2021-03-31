//
//  WalletDetailRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2021.
//

import UIKit
import RxSwift
import Action

class WalletDetailRootView: BEView {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let viewModel: WalletDetailViewModel
    
    // MARK: - Subviews
    lazy var headerStackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill)
    
    lazy var coinLogoImageView = CoinLogoImageView(width: 35, height: 35)
    
    lazy var walletNameTextField: UITextField = {
        let tf = UITextField(font: .systemFont(ofSize: 19, weight: .semibold), placeholder: "A", autocorrectionType: .no)
        tf.isUserInteractionEnabled = false
        return tf
    }()
    
    lazy var walletDescriptionLabel = UILabel(textSize: 13, weight: .medium, textColor: .textSecondary)
    
    lazy var settingsButton = UIImageView(width: 25, height: 25, image: .settings, tintColor: .a3a5ba)
    
    lazy var collectionView: TransactionsCollectionView = {
        let collectionView = TransactionsCollectionView(viewModel: viewModel.transactionsVM, sections: [
            CollectionViewSection(
                header: CollectionViewSection.Header(
                    viewClass: WDVCSectionHeaderView.self,
                    title: L10n.activity
                ),
                cellType: TransactionCell.self,
                interGroupSpacing: 2,
                itemHeight: .absolute(71)
            )
        ])
        collectionView.itemDidSelect = { [unowned self] in
            self.viewModel.navigationSubject.onNext(.transactionInfo($0))
        }
        collectionView.receiveAction = CocoaAction { [unowned self] in
            self.viewModel.receiveTokens()
            return .just(())
        }
        return collectionView
    }()
    
    lazy var tabBar: TabBar = {
        let tabBar = TabBar(cornerRadius: 20, contentInset: .init(x: 20, y: 10))
        tabBar.backgroundColor = .h202020
        return tabBar
    }()
    
    // MARK: - Initializers
    init(viewModel: WalletDetailViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        backgroundColor = .vcBackground
        layout()
        bind()
    }
    
    // MARK: - Layout
    private func layout() {
        // Header stackView
        addSubview(headerStackView)
        headerStackView.autoPinEdgesToSuperviewEdges(with: .init(top: 20, left: 0, bottom: 0, right: 0), excludingEdge: .bottom)
        
        headerStackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
                coinLogoImageView,
                BEStackViewSpacing(16),
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    walletNameTextField,
                    walletDescriptionLabel
                ]),
                BEStackViewSpacing(10),
                settingsButton
                    .onTap(viewModel, action: #selector(WalletDetailViewModel.showWalletSettings))
            ])
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            UIView.separator(height: 2, color: .separator),
            BEStackViewSpacing(0)
        ])
        
        // collection view
        addSubview(collectionView)
        collectionView.autoPinEdge(.top, to: .bottom, of: headerStackView)
        collectionView.autoPinEdge(toSuperviewEdge: .leading)
        collectionView.autoPinEdge(toSuperviewEdge: .trailing)
        
        // tabBar
        addSubview(tabBar)
        tabBar.autoPinEdge(.top, to: .bottom, of: collectionView)
        tabBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        
        tabBar.stackView.addArrangedSubviews([
//            UIImageView(width: 24, height: 24, image: .walletAdd, tintColor: .white)
//                .padding(.init(all: 16)),
            UIImageView(width: 24, height: 24, image: .walletReceive, tintColor: .white)
                .padding(.init(all: 16))
                .onTap(viewModel, action: #selector(WalletDetailViewModel.receiveTokens)),
            UIImageView(width: 24, height: 24, image: .walletSend, tintColor: .white)
                .padding(.init(all: 16))
                .onTap(viewModel, action: #selector(WalletDetailViewModel.sendTokens)),
            UIImageView(width: 24, height: 24, image: .walletSwap, tintColor: .white)
                .padding(.init(all: 16))
                .onTap(viewModel, action: #selector(WalletDetailViewModel.swapTokens))
        ])
    }
    
    private func bind() {
        let walletDriver = viewModel.wallet
            .asDriver(onErrorJustReturn: nil)
            .filter {$0 != nil}
            .map {$0!}
        
        walletDriver
            .map {$0.symbol == "SOL"}
            .drive(settingsButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        walletDriver
            .map {$0.name}
            .drive(walletNameTextField.rx.text)
            .disposed(by: disposeBag)
        
        walletDriver
            .map {$0.description}
            .drive(walletDescriptionLabel.rx.text)
            .disposed(by: disposeBag)
        
        walletDriver
            .drive(onNext: {wallet in
                self.coinLogoImageView.setUp(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        walletDriver
            .drive(onNext: {[unowned self] wallet in
                self.collectionView.wallet = wallet
                if let header = self.collectionView.headerForSection(0) as? WDVCSectionHeaderView
                {
                    self.collectionView.reloadHeader(header)
                }
            })
            .disposed(by: disposeBag)
        
        // bind controls to view model
        walletNameTextField.rx.text.orEmpty
            .skip(1)
            .map {$0.trimmingCharacters(in: .whitespacesAndNewlines)}
            .distinctUntilChanged()
            .subscribe(onNext: {[unowned self] in
                if let wallet = self.viewModel.wallet.value {
                    var newName = $0
                    if $0.isEmpty {
                        // fall back to wallet name
                        newName = wallet.name
                    }
                    self.viewModel.walletsVM.updateWallet(wallet, withName: newName)
                }
                
            })
            .disposed(by: disposeBag)
        
        walletNameTextField.delegate = self
    }
}

extension WalletDetailRootView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        walletNameTextField.isUserInteractionEnabled = false
        return true
    }
}
