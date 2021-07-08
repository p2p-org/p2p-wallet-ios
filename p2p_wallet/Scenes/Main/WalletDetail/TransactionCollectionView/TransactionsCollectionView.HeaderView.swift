//
//  TransactionsCollectionView.HeaderView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/07/2021.
//

import Foundation
import RxSwift
import RxCocoa
import Action

extension TransactionsCollectionView {
    class HeaderView: BaseCollectionReusableView {
        override var padding: UIEdgeInsets {
            super.padding.modifying(dTop: 16, dBottom: 16)
        }
        
        // MARK: - Dependencies
        fileprivate var graphViewModel: WalletGraphViewModel?
        fileprivate var analyticsManager: AnalyticsManagerType?
        fileprivate var scanQrCodeAction: CocoaAction?
        fileprivate var wallet: Driver<Wallet?>?
        fileprivate var solPubkey: Driver<String?>?
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var didInjectDependencies = false
        
        // MARK: - Subviews
        lazy var amountLabel = UILabel(text: "$120,00", textSize: 27, weight: .bold)
        lazy var tokenCountLabel = UILabel(text: "0 SOL", textColor: .textSecondary)
        lazy var changeLabel = UILabel(textColor: .attentionGreen)
        lazy var lineChartView = ChartView()
        lazy var chartPicker: HorizontalPicker = {
            let chartPicker = HorizontalPicker(forAutoLayout: ())
            chartPicker.labels = Period.allCases.map {$0.shortString}
            chartPicker.selectedIndex = Period.allCases.firstIndex(where: {$0 == .last1h})!
            chartPicker.delegate = self
            return chartPicker
        }()
        lazy var walletAddressLabel = UILabel(text: L10n.walletAddress, textSize: 13, weight: .medium, textColor: .textSecondary)
        lazy var pubkeyLabel = UILabel(weight: .medium)
        lazy var headerLabel = UILabel(text: L10n.activity, textSize: 21, weight: .semibold)
        
        // MARK: - Initializer
        override func commonInit() {
            super.commonInit()
            stackView.alignment = .fill
            stackView.spacing = 0
            
            stackView.addArrangedSubviews {
                amountLabel
                    .padding(.init(x: 20, y: 0))
                BEStackViewSpacing(10)
                
                tokenCountLabel
                    .padding(.init(x: 20, y: 0))
                BEStackViewSpacing(16)
                
                UIView.defaultSeparator(height: 2)
                BEStackViewSpacing(0)
                
                lineChartView
                    .padding(.init(x: -10, y: 0))
                BEStackViewSpacing(0)
                
                UIView.defaultSeparator()
                BEStackViewSpacing(10)
                
                chartPicker
                    .padding(.init(x: 20, y: 0))
                BEStackViewSpacing(20)
                
                UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill) {
                    UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                        walletAddressLabel
                        pubkeyLabel
                    }
                        .with(spacing: 5)
                        .onTap(self, action: #selector(buttonCopyToClipboardDidTouch))
                    
                    UIImageView(width: 24.75, height: 24.75, image: .scanQr2, tintColor: .h5887ff)
                        .onTap(self, action: #selector(buttonScanQrCodeDidTouch))
                }
                    .with(spacing: 20, alignment: .center, distribution: .fill)
                    .padding(.init(x: 16, y: 10), backgroundColor: .background4.onDarkMode(.h8d8d8d.withAlphaComponent(0.1)), cornerRadius: 12)
                    .padding(.init(x: 20, y: 0))
                BEStackViewSpacing(40)
                
                headerLabel
                    .padding(.init(x: 20, y: 0))
            }
        }
        
        // MARK: - Methods
        func setUp(
            graphViewModel: WalletGraphViewModel,
            analyticsManager: AnalyticsManagerType,
            scanQrCodeAction: CocoaAction,
            wallet: Driver<Wallet?>,
            solPubkey: Driver<String?>
        ) {
            // prevent dupplicating
            guard !didInjectDependencies else {return}
            
            // setup dependencies
            self.graphViewModel = graphViewModel
            self.analyticsManager = analyticsManager
            self.scanQrCodeAction = scanQrCodeAction
            self.wallet = wallet
            self.solPubkey = solPubkey
            
            // bind
            bind()
            
            // set dependencies as injected
            didInjectDependencies = true
        }
        
        private func bind() {
            // amountLabel
            wallet?.map {
                $0?.amountInCurrentFiat
                    .toString(autoSetMaximumFractionDigits: true)
            }
                .map {Defaults.fiat.symbol + " " + ($0 ?? "0")}
                .drive(amountLabel.rx.text)
                .disposed(by: disposeBag)
            
            // tokenlabel
            wallet?.map {
                "\($0?.token.symbol ?? "") \($0?.amount.toString(maximumFractionDigits: 9) ?? "")"
            }
                .drive(tokenCountLabel.rx.text)
                .disposed(by: disposeBag)
            
            // changeLabel
            wallet?.map {
                "\($0?.price?.change24h?.percentage?.toString(maximumFractionDigits: 2, showPlus: true) ?? "")% \(L10n._24Hours)"
            }
                .drive(changeLabel.rx.text)
                .disposed(by: disposeBag)
            
            wallet?.map {
                $0?.price?.change24h?.percentage >= 0 ? UIColor.attentionGreen: UIColor.alert
            }
                .drive(changeLabel.rx.textColor)
                .disposed(by: disposeBag)
            
            // chart view
            if let graphViewModel = graphViewModel {
                lineChartView
                    .subscribed(to: graphViewModel)
                    .disposed(by: disposeBag)
            }
            
            // sol pubkey
            solPubkey?
                .drive(pubkeyLabel.rx.text)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func buttonCopyToClipboardDidTouch() {
            UIApplication.shared.copyToClipboard(pubkeyLabel.text, alert: false)
            analyticsManager?.log(event: .tokenDetailsAddressCopy)
            walletAddressLabel.text = L10n.addressCopied
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.walletAddressLabel.text = L10n.walletAddress
            }
        }
        
        @objc private func buttonScanQrCodeDidTouch() {
            scanQrCodeAction?.execute()
        }
    }
}

extension TransactionsCollectionView.HeaderView: HorizontalPickerDelegate {
    func picker(_ picker: HorizontalPicker, didSelectOptionAtIndex index: Int) {
        guard index < Period.allCases.count else {return}
        graphViewModel?.period = Period.allCases[index]
        graphViewModel?.reload()
    }
}
