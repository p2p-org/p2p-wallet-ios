//
//  ReceiveToken.SelectBTCTypeViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

extension ReceiveToken {
    class SelectBTCTypeViewController: WLIndicatorModalFlexibleHeightVC {
        private let viewModel: ReceiveTokenBitcoinViewModelType
        private let options: [BTCTypeOption] = [.splBTC, .renBTC]
        
        private let selectView: SelectOptionView<BTCTypeOption>
        private lazy var doneButton = WLButton.stepButton(type: .blue, label: L10n.done)
            .onTap(self, action: #selector(buttonDoneDidTouch))
        
        init(viewModel: ReceiveTokenBitcoinViewModelType, selectedOption: BTCTypeOption) {
            self.viewModel = viewModel
            self.selectView = .init(options: options, selectedIndex: options.firstIndex(of: selectedOption)!) { option, isSelected in
                let view = WLDefaultOptionView()
                view.label.text = option.stringValue
                view.setSelected(isSelected)
                return view
            }
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            title = L10n.iWantToReceive
            stackView.addArrangedSubviews {
                selectView.padding(.init(x: 20, y: 0))
                doneButton.padding(.init(x: 20, y: 0))
            }
        }
        
        @objc private func buttonDoneDidTouch() {
            if let selectedOption = options[safe: selectView.selectedIndex] {
                viewModel.toggleIsReceivingRenBTC(isReceivingRenBTC: selectedOption == .renBTC)
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    enum BTCTypeOption: String {
        case splBTC
        case renBTC
        
        var stringValue: String {
            switch self {
            case .splBTC:
                return "SPL BTC"
            case .renBTC:
                return "renBTC"
            }
        }
    }
}
