//
//  ReceiveToken.SelectBTCTypeViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

extension ReceiveToken {
    enum BTCTypeOption: String {
        case splBTC
        case renBTC
    }
    
    class BTCOptionView: BEView, OptionViewType {
        private lazy var label = UILabel(text: nil)
        
        private lazy var radioButton: WLRadioButton = {
            let checkBox = WLRadioButton()
            checkBox.isUserInteractionEnabled = false
            return checkBox
        }()
        
        override func commonInit() {
            super.commonInit()
            let stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                radioButton, label
            ])
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 0, y: 20))
        }
        
        func setOption(_ option: BTCTypeOption) {
            label.text = option.rawValue
        }
        
        func setSelected(_ selected: Bool) {
            radioButton.isSelected = selected
        }
    }
    
    class SelectBTCTypeViewController: WLIndicatorModalFlexibleHeightVC {
        private let options: [BTCTypeOption] = [.splBTC, .renBTC]
        
        private let selectView: SelectOptionView<BTCTypeOption>
        
        init(selectedOption: BTCTypeOption) {
            self.selectView = .init(options: options, selectedIndex: options.firstIndex(of: selectedOption)!) { option, isSelected in
                let view = BTCOptionView()
                view.setOption(option)
                view.setSelected(isSelected)
                return view
            }
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            stackView.addArrangedSubview(selectView)
        }
    }
}
