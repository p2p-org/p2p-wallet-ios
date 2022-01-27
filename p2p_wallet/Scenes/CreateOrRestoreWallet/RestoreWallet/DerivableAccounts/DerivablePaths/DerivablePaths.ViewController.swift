//
//  DerivationPaths.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import Foundation
import BECollectionView

extension DerivablePaths {
    typealias Callback = (SolanaSDK.DerivablePath) -> Void
    
    class ViewController: WLBottomSheet, BECollectionViewDelegate {
        // MARK: - Properties
        private let initPath: SolanaSDK.DerivablePath
        private let viewModel: ViewModel
        private let onSelect: Callback?
        
        override var margin: UIEdgeInsets {
            .init(x: 10, y: 0)
        }
        
        // MARK: - Initializers
        init(currentPath: SolanaSDK.DerivablePath, onSelect: Callback?) {
            initPath = currentPath
            viewModel = ViewModel(currentPath: currentPath)
            self.onSelect = onSelect
            super.init()
            modalPresentationStyle = .custom
            transitioningDelegate = self
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            viewModel.reload()
        }
        
        override func setUp() {
            super.setUp()
            
            view.backgroundColor = .clear
            
            stackView.addArrangedSubviews {
                // Actions
                UIStackView(axis: .vertical, alignment: .fill, distribution: .fill) {
                    // Header
                    UILabel(text: L10n.derivationPath, textSize: 13, weight: .semibold, textColor: .textSecondary, textAlignment: .center)
                        .padding(.init(x: 0, y: 15))
                    UIView.defaultSeparator()
                    
                    // Derivable paths
                    SolanaSDK.DerivablePath.DerivableType
                        .allCases
                        .map { SolanaSDK.DerivablePath(type: $0, walletIndex: 0, accountIndex: 0) }
                        .enumerated()
                        .map { (index, path) -> UIView in
                            let selected = path == initPath
                            
                            return UIStackView(axis: .vertical, alignment: .fill, distribution: .fill) {
                                UIStackView(axis: .horizontal, alignment: .center) {
                                    UILabel(text: path.title, textSize: 17, weight: selected ? .semibold : .regular)
                                    UIView.spacer
                                    selected ? UIImageView(width: 22, height: 22, image: .checkBoxIOS) : UIView()
                                }.padding(.init(top: 0, left: 20, bottom: 0, right: 24))
                                UIView.defaultSeparator()
                            }.withTag(index)
                                .frame(height: 55)
                                .onTap(self, action: #selector(onPathSelect))
                            
                        }
                }.padding(.zero, backgroundColor: .background, cornerRadius: 14)
                
                // Cancel
                WLButton.stepButton(type: .white, label: L10n.cancel)
                    .onTap(self, action: #selector(back))
            }
            
        }
        
        @objc func onPathSelect(gesture: UITapGestureRecognizer) {
            dismiss(animated: true)
            
            guard let tag = gesture.view?.tag else { return }
            let pathType = SolanaSDK.DerivablePath.DerivableType.allCases[tag]
            onSelect?(.init(type: pathType, walletIndex: 0, accountIndex: 0))
        }
    }
}
