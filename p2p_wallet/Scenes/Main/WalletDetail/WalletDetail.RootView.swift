//
//  WalletDetail.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import UIKit
import RxSwift
import RxCocoa
import Action
import BECollectionView

extension WalletDetail {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: ViewModel
        
        // MARK: - Subviews
        lazy var headerStackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill)
        
        lazy var coinLogoImageView = CoinLogoImageView(size: 35)
        
        lazy var walletNameTextField: UITextField = {
            let tf = UITextField(font: .systemFont(ofSize: 19, weight: .semibold), placeholder: "A", autocorrectionType: .no)
            tf.isUserInteractionEnabled = false
            return tf
        }()
        
        lazy var walletDescriptionLabel = UILabel(textSize: 13, weight: .medium, textColor: .textSecondary)
        
        lazy var settingsButton = UIImageView(width: 25, height: 25, image: .settings, tintColor: .a3a5ba)
        
        lazy var collectionView: TransactionsCollectionView = {
            let collectionView = TransactionsCollectionView(
                transactionViewModel: viewModel.output.transactionsViewModel,
                graphViewModel: viewModel.output.graphViewModel,
                analyticsManager: viewModel.analyticsManager,
                scanQrCodeAction: CocoaAction { [weak self] in
                    self?.viewModel.receiveTokens()
                    return .just(())
                },
                wallet: viewModel.output.wallet,
                solPubkey: viewModel.output.solPubkey
            )
            collectionView.delegate = self
            return collectionView
        }()
        
        lazy var tabBar: TabBar = {
            let tabBar = TabBar(cornerRadius: 20, contentInset: .init(x: 20, y: 10))
            tabBar.backgroundColor = .h202020
            return tabBar
        }()
        
        // MARK: - Initializers
        init(viewModel: ViewModel) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
            walletNameTextField.delegate = self
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            collectionView.refresh()
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
                        .onTap(viewModel, action: #selector(ViewModel.showWalletSettings))
                ])
                    .padding(.init(x: 20, y: 0)),
                BEStackViewSpacing(20),
                UIView.defaultSeparator(height: 2),
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
                    .onTap(viewModel, action: #selector(ViewModel.receiveTokens)),
                UIImageView(width: 24, height: 24, image: .walletSend, tintColor: .white)
                    .padding(.init(all: 16))
                    .onTap(viewModel, action: #selector(ViewModel.sendTokens)),
                UIImageView(width: 24, height: 24, image: .walletSwap, tintColor: .white)
                    .padding(.init(all: 16))
                    .onTap(viewModel, action: #selector(ViewModel.swapTokens))
            ])
        }
        
        private func bind() {
            // bind controls to viewModel's input
            walletNameTextField.rx.text.orEmpty
                .skip(1)
                .map {$0.trimmingCharacters(in: .whitespacesAndNewlines)}
                .distinctUntilChanged()
                .bind(to: viewModel.input.walletName)
                .disposed(by: disposeBag)
            
            // bind viewModel's output to controls
            viewModel.output.wallet
                .map {$0?.token.symbol == "SOL"}
                .drive(settingsButton.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.output.wallet
                .map {$0?.name}
                .drive(walletNameTextField.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.output.wallet
                .map {$0?.token.name}
                .drive(walletDescriptionLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.output.wallet
                .drive(onNext: { [weak self] wallet in
                    self?.coinLogoImageView.setUp(wallet: wallet)
                })
                .disposed(by: disposeBag)
            
            // log
            viewModel.output.transactionsViewModel
                .dataDidChange
                .map {[weak self] _ in self?.viewModel.output.transactionsViewModel.getCurrentPage()}
                .distinctUntilChanged()
                .subscribe(onNext: {[weak self] currentPage in
                    guard let currentPage = currentPage else {return}
                    self?.viewModel.analyticsManager.log(event: .tokenDetailsActivityScroll(pageNum: currentPage))
                })
                .disposed(by: disposeBag)
        }
    }
}

extension WalletDetail.RootView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        walletNameTextField.isUserInteractionEnabled = false
        return true
    }
}

extension WalletDetail.RootView: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let transaction = item as? SolanaSDK.ParsedTransaction else {return}
        viewModel.showTransaction(transaction)
    }
}
