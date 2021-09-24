//
//  DerivationPaths.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import Foundation
import BECollectionView

protocol DerivablePathsVCDelegate: AnyObject {
    func derivablePathsVC(_ vc: DerivablePaths.ViewController, didSelectPath path: SolanaSDK.DerivablePath)
}

extension DerivablePaths {
    class ViewController: WLIndicatorModalVC, BECollectionViewDelegate {
        // MARK: - Properties
        private let initPath: SolanaSDK.DerivablePath
        private let viewModel: ViewModel
        weak var delegate: DerivablePathsVCDelegate?
        
        // MARK: - Subviews
        private lazy var collectionView = BEStaticSectionsCollectionView(
            sections: [
                .init(
                    index: 0,
                    layout: .init(
                        cellType: Cell.self,
                        itemHeight: .estimated(64)
                    ),
                    viewModel: viewModel
                )
            ]
        )
        
        // MARK: - Initializers
        init(currentPath: SolanaSDK.DerivablePath) {
            initPath = currentPath
            viewModel = ViewModel(currentPath: currentPath)
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
            let headerStackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill) {
                UILabel(text: L10n.selectDerivablePath, textSize: 17, weight: .semibold)
                UILabel(text: L10n.ByDefaultP2PWalletWillUseM4450100AsTheDerivationPathForTheMainWallet.toUseAnAlternativePathTryRestoringAnExistingWallet, textSize: 15, textColor: .textSecondary, numberOfLines: 0)
            }
            containerView.addSubview(headerStackView)
            headerStackView.autoPinEdgesToSuperviewEdges(with: .init(all: 20), excludingEdge: .bottom)
            
            let separator = UIView.defaultSeparator()
            containerView.addSubview(separator)
            separator.autoPinEdge(.top, to: .bottom, of: headerStackView, withOffset: 20)
            separator.autoPinEdge(toSuperviewEdge: .leading)
            separator.autoPinEdge(toSuperviewEdge: .trailing)
            
            containerView.addSubview(collectionView)
            collectionView.autoPinEdge(.top, to: .bottom, of: separator)
            collectionView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            collectionView.delegate = self
        }
        
        func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
            guard let path = item as? SelectableDerivablePath else {return}
            var paths = viewModel.data
            for i in 0..<paths.count {
                paths[i].isSelected = false
                if paths[i].path == path.path {
                    paths[i].isSelected = true
                }
            }
            viewModel.overrideData(by: paths)
            delegate?.derivablePathsVC(self, didSelectPath: path.path)
        }
    }
}

extension DerivablePaths.ViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        CustomHeightPresentationController(
            height: { 362 },
            presentedViewController: presented,
            presenting: presenting
        )
    }
}
