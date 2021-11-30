//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import UIKit
import RxSwift
import BEPureLayout

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
        
        // MARK: - Subviews
        private lazy var titleView = TitleView(forConvenience: ())
        private lazy var addressInputView = AddressInputView(viewModel: viewModel)
        private lazy var addressView = AddressView(forConvenience: ())
        private lazy var collectionView = UILabel(text: "collection")
        private lazy var networkView = NetworkView(forConvenience: ())
        
        // MARK: - Initializer
        init(viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        // MARK: - Layout
        private func layout() {
            scrollView.contentInset.modify(dTop: -.defaultPadding)
            stackView.addArrangedSubviews {
                UIView.floatingPanel {
                    titleView
                    BEStackViewSpacing(20)
                    addressInputView
                    addressView
                }
                BEStackViewSpacing(18)
                networkView
                collectionView
            }
        }
        
        private func bind() {
            // input state
            let isEnteringDriver = viewModel.inputStateDriver.map {$0.isEntering}
                .distinctUntilChanged()
            
            isEnteringDriver.map {!$0}
                .drive(titleView.scanQrCodeButton.rx.isHidden)
                .disposed(by: disposeBag)
            
            isEnteringDriver.map {!$0}
                .drive(titleView.pasteQrCodeButton.rx.isHidden)
                .disposed(by: disposeBag)
            
            isEnteringDriver.map {!$0}
                .drive(addressInputView.rx.isHidden)
                .disposed(by: disposeBag)
            
            isEnteringDriver
                .drive(addressView.rx.isHidden)
                .disposed(by: disposeBag)
            
            isEnteringDriver.map {!$0}
                .drive(collectionView.rx.isHidden)
                .disposed(by: disposeBag)
            
            isEnteringDriver
                .drive(networkView.rx.isHidden)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func showDetail() {
            viewModel.navigate(to: .detail)
        }
    }
}
