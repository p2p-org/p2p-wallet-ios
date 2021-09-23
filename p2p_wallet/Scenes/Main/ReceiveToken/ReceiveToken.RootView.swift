//
//  ReceiveToken.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift

extension ReceiveToken {
    class RootView: ScrollableVStackRootView, SwitcherDelegate {
        // MARK: - Constants
        private let disposeBag = DisposeBag()
        private let allTokenTypes = TokenType.allCases
        
        // MARK: - Properties
        private let viewModel: ReceiveTokenViewModelType
        
        // MARK: - Subviews
        private lazy var switcher = Switcher()
        private lazy var receiveSolanaView = ReceiveSolanaView(viewModel: viewModel.receiveSolanaViewModel)
        private lazy var receiveBTCView = ReceiveBitcoinView(
            viewModel: viewModel.receiveBitcoinViewModel,
            receiveSolanaViewModel: viewModel.receiveSolanaViewModel
        )
        
        // MARK: - Initializers
        init(viewModel: ReceiveTokenViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        func layout() {
            switcher.labels = allTokenTypes.map {$0.localizedName}
            switcher.delegate = self
            
            scrollView.contentInset.modify(dLeft: -.defaultPadding, dRight: -.defaultPadding)
            
            stackView.spacing = 20
            stackView.addArrangedSubviews {
                receiveSolanaView
                receiveBTCView
            }
            
            if viewModel.shouldShowChainsSwitcher {
                stackView.insertArrangedSubview(switcher.centeredHorizontallyView, at: 0)
            }
        }
        
        func bind() {
            viewModel.tokenTypeDriver
                .drive(onNext: {[weak self] token in
                    switch token {
                    case .solana:
                        self?.receiveSolanaView.isHidden = false
                        self?.receiveBTCView.isHidden = true
                    case .btc:
                        self?.receiveSolanaView.isHidden = true
                        self?.receiveBTCView.isHidden = false
                    }
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        fileprivate func switcher(_ switcher: Switcher, didChangeIndexTo index: Int) {
            guard let token = allTokenTypes[safe: index] else {return}
            viewModel.switchToken(token)
        }
    }
}

private protocol SwitcherDelegate: AnyObject {
    func switcher(_ switcher: Switcher, didChangeIndexTo index: Int)
}

private class Switcher: BEView {
    private let disabledColor: UIColor = .f6f6f8Static
    private let disabledTextColor: UIColor = .a3a5baStatic
    private let enabledColor: UIColor = .h5887ff
    private let enabledTextColor: UIColor = .white
    
    private lazy var stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill)
    weak var delegate: SwitcherDelegate?
    
    var labels: [String] = [] {
        didSet {
            reloadData()
            selectedIndex = 0
        }
    }
    
    var selectedIndex: Int = 0 {
        didSet { changeSelectedIndex() }
    }
    
    override func commonInit() {
        super.commonInit()
        // add stackView
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
    
    private func reloadData() {
        stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
        stackView.addArrangedSubviews(
            labels.enumerated().map {index, label -> UIView in
                let view = UILabel(text: label, textSize: 15, weight: .medium, textColor: disabledTextColor)
                    .withContentHuggingPriority(.required, for: .horizontal)
                    .padding(.init(x: 12, y: 14), backgroundColor: disabledColor, cornerRadius: 12)
                
                let gesture = TapGesture(target: self, action: #selector(viewDidTap(gesture:)))
                gesture.index = index
                view.addGestureRecognizer(gesture)
                
                return view
            }
        )
    }
    
    private func changeSelectedIndex() {
        for (index, view) in stackView.arrangedSubviews.enumerated() {
            if index != selectedIndex && view.backgroundColor == enabledColor {
                view.backgroundColor = disabledColor
                (view.subviews.first as? UILabel)?.textColor = disabledTextColor
            }
            
            if index == selectedIndex && view.backgroundColor == disabledColor {
                view.backgroundColor = enabledColor
                (view.subviews.first as? UILabel)?.textColor = enabledTextColor
            }
        }
        
        // Animation:
    }
    
    @objc private func viewDidTap(gesture: TapGesture) {
        guard selectedIndex != gesture.index else {return}
        selectedIndex = gesture.index
        delegate?.switcher(self, didChangeIndexTo: selectedIndex)
    }
    
    private class TapGesture: UITapGestureRecognizer {
        var index: Int!
    }
}
