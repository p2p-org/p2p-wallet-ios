//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import UIKit
import RxSwift

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
        
        // MARK: - Subviews
        private lazy var scanQrCodeButton = createButton(image: .scanQr, text: L10n.scanQR)
        private lazy var pasteQrCodeButton = createButton(image: .buttonPaste, text: L10n.paste.uppercaseFirst)
        
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
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            
        }
        
        // MARK: - Layout
        private func layout() {
            
        }
        
        private func bind() {
            
        }
        
        // MARK: - Actions
        @objc private func showDetail() {
            viewModel.navigate(to: .detail)
        }
        
        // MARK: - Helpers
        private func createButton(image: UIImage, text: String) -> UIView {
            UIStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill) {
                UIImageView(width: 20, height: 20, image: image)
                UILabel(text: text, textSize: 15, weight: .medium, textColor: .h5887ff)
            }
        }
    }
}
