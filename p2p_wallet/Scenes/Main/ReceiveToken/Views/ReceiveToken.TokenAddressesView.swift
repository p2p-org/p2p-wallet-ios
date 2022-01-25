//
//  ReceiveToken.TokenAddressesView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 20.01.2022.
//

import BEPureLayout
import RxSwift

extension ReceiveToken {
    final class TokenAddressesView: UIStackView {
        private let viewModel: ReceiveSceneModel
        private let disposeBag = DisposeBag()

        private lazy var directAddressLine = HorizontalLabelsWithSpacer()
            .onLongTap(self, action: #selector(directAddressLongTap))
        private lazy var mintAddressLine = HorizontalLabelsWithSpacer()
            .onLongTap(self, action: #selector(mintAddressLongTap))
        private let tapAndHoldView = TapAndHoldView()
        private lazy var fullTapAndHoldView = UIView.greyBannerView {
            tapAndHoldView
        }

        init(viewModel: ReceiveSceneModel) {
            self.viewModel = viewModel

            super.init(frame: .zero)

            configure()
            bind()
            build()
        }

        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func build() {
            axis = .vertical
            spacing = 18

            addArrangedSubviews {
                directAddressLine
                UIView(height: 1, backgroundColor: .f2f2f7)
                mintAddressLine
                BEStackViewSpacing(36)
                fullTapAndHoldView
            }
        }

        private func configure() {
            directAddressLine.configureLeftLabel { label in
                label.autoSetDimension(.width, toSize: 88)
                label.numberOfLines = 0
                label.text = L10n.directAddress(
                    viewModel.tokenWallet?.token.symbol ?? ""
                )
                label.textColor = .h8e8e93
                label.font = .systemFont(ofSize: 15)
            }

            directAddressLine.configureRightLabel { label in
                label.textAlignment = .right
                label.numberOfLines = 0
                label.text = viewModel.tokenWallet?.pubkey
                label.font = .systemFont(ofSize: 15)
            }

            mintAddressLine.configureLeftLabel { label in
                label.autoSetDimension(.width, toSize: 88)
                label.numberOfLines = 0
                label.text = L10n.mintAddress(
                    viewModel.tokenWallet?.token.symbol ?? ""
                )
                label.textColor = .h8e8e93
                label.font = .systemFont(ofSize: 15)
            }

            mintAddressLine.configureRightLabel { label in
                label.textAlignment = .right
                label.numberOfLines = 0
                label.text = viewModel.tokenWallet?.mintAddress
                label.font = .systemFont(ofSize: 15)
            }

            tapAndHoldView.closeHandler = { [weak self] in
                self?.viewModel.hideAddressesHintSubject.accept(())
            }
        }

        private func bind() {
            viewModel.addressesHintIsHiddenDriver
                .drive(fullTapAndHoldView.rx.isHidden)
                .disposed(by: disposeBag)
        }

        @objc
        func directAddressLongTap(recognizer: UILongPressGestureRecognizer) {
            if recognizer.state == .began {
                viewModel.copyDirectAddress()
            }
        }

        @objc
        func mintAddressLongTap(recognizer: UILongPressGestureRecognizer) {
            if recognizer.state == .began {
                viewModel.copyMintAddress()
            }
        }
    }
}
