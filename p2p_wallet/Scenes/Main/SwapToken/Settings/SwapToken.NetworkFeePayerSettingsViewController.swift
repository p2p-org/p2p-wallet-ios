//
//  SwapToken.NetworkFeePayerSettingsViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/08/2021.
//

import Foundation

extension SwapToken {
    class NetworkFeePayerSettingsViewController: SettingsBaseViewController {
        // MARK: - Properties
        private let transactionTokenName: String?
        private var payingToken: PayingToken = Defaults.payingToken
        private lazy var allCells = PayingToken.allCases.map { token -> RadioCell in
            let cell = RadioCell(forAutoLayout: ())
            cell.label.attributedText = NSMutableAttributedString()
                .text(token.description, size: 17, weight: .medium)
                .text(token == .nativeSOL ? " (SOL)": transactionTokenName == nil ? "": " (\(transactionTokenName!))", size: 17, weight: .medium, color: .textSecondary)
            cell.method = token
            cell.onTap(self, action: #selector(cellDidTap(_:)))
            return cell
        }
        private lazy var doneButton = WLButton.stepButton(type: .blue, label: L10n.done)
            .onTap(self, action: #selector(buttonDoneDidTouch))
        var completion: ((PayingToken) -> Void)?
        
        init(transactionTokenName: String?) {
            self.transactionTokenName = transactionTokenName
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            title = L10n.payNetworkFeeWith
            reloadData()
        }
        
        override func setUpContent(stackView: UIStackView) {
            stackView.spacing = 0
            stackView.addArrangedSubviews(allCells)
            stackView.addArrangedSubview(doneButton)
        }
        
        @objc private func cellDidTap(_ gesture: UITapGestureRecognizer) {
            guard let cell = gesture.view as? RadioCell,
                  let method = cell.method
            else {return}
            payingToken = method
            reloadData()
        }
        
        @objc private func buttonDoneDidTouch() {
            completion?(payingToken)
            back()
        }
        
        func reloadData() {
            for cell in allCells {
                cell.radioButton.isSelected = cell.method == payingToken
            }
        }
    }
}

private extension SwapToken {
    class RadioCell: BEView {
        var method: PayingToken?
        
        lazy var label = UILabel(text: nil)
        
        lazy var radioButton: WLRadioButton = {
            let checkBox = WLRadioButton()
            checkBox.isUserInteractionEnabled = false
            return checkBox
        }()
        
        override func commonInit() {
            super.commonInit()
            backgroundColor = .contentBackground
            let stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                radioButton, label
            ])
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 0, y: 20))
        }
    }
}
