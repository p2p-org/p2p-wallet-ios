//
//  WalletDetailRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2021.
//

import UIKit
import RxSwift

class WalletDetailRootView: BEView {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let viewModel: WalletDetailViewModel
    
    // MARK: - Subviews
    lazy var headerStackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill)
    
    lazy var coinLogoImageView = CoinLogoImageView(width: 35, height: 35, cornerRadius: 12)
    
    lazy var walletNameTextField: UITextField = {
        let tf = UITextField(font: .systemFont(ofSize: 19, weight: .semibold), placeholder: "A", autocorrectionType: .no)
        tf.isUserInteractionEnabled = false
        return tf
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
        layout()
        bind()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        bringSubviewToFront(tabBar)
        // update prices
        PricesManager.shared.fetchCurrentPrices()
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
                walletNameTextField
                    .withContentHuggingPriority(.required, for: .horizontal),
                BEStackViewSpacing(0),
                UILabel(text: " \(L10n.walletRename)", textSize: 19, weight: .semibold),
                BEStackViewSpacing(10),
                UIImageView(width: 16, height: 18, image: .buttonEdit, tintColor: .a3a5ba)
                    .onTap(viewModel, action: #selector(WalletDetailViewModel.showWalletSettings))
            ])
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            UIView.separator(height: 2, color: .separator),
            BEStackViewSpacing(0)
        ])
        
        // tabBar
        addSubview(tabBar)
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
        viewModel.wallet
            .map {$0?.name}
            .asDriver(onErrorJustReturn: nil)
            .drive(walletNameTextField.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.wallet
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: {wallet in
                self.coinLogoImageView.setUp(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        // bind controls to view model
        walletNameTextField.rx.text.orEmpty
            .skip(1)
            .map {$0.trimmingCharacters(in: .whitespacesAndNewlines)}
            .distinctUntilChanged()
            .subscribe(onNext: {
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
