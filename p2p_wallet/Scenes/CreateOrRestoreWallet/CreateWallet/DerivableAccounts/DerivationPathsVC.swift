//
//  DerivationPathsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import Foundation
import BECollectionView
import RxSwift

class DerivablePathCell: BaseCollectionViewCell, LoadableView, BECollectionViewCell {
    var loadingViews: [UIView] {[radioButton, titleLabel]}
    
    private lazy var radioButton = WLRadioButton()
    private lazy var titleLabel = UILabel(textSize: 17, numberOfLines: 0)
    
    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .horizontal, spacing: 20, alignment: .center, distribution: .fill) {
            radioButton
            titleLabel
        }
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(all: 22))
    }
    
    func setUp(with item: AnyHashable?) {
        guard let path = item as? SelectableDerivablePath else {return}
        radioButton.isSelected = path.isSelected
        titleLabel.text = path.path.rawValue
    }
}

class DerivablePathsViewModel: BEListViewModel<SelectableDerivablePath> {
    private let currentPath: SolanaSDK.DerivablePath
    init(currentPath: SolanaSDK.DerivablePath) {
        self.currentPath = currentPath
    }
    
    override func createRequest() -> Single<[SelectableDerivablePath]> {
        let paths = SolanaSDK.DerivablePath.allCases
            .map {
                SelectableDerivablePath(
                    path: $0,
                    isSelected: $0 == currentPath
                )
            }
        return .just(paths)
    }
}

class DerivablePathsVC: BaseVC, BECollectionViewDelegate {
    // MARK: - Properties
    private let initPath: SolanaSDK.DerivablePath
    private let viewModel: DerivablePathsViewModel
    var completion: ((SolanaSDK.DerivablePath) -> Void)?
    
    // MARK: - Subviews
    private lazy var collectionView = BECollectionView(
        sections: [
            .init(
                index: 0,
                layout: .init(
                    cellType: DerivablePathCell.self,
                    itemHeight: .estimated(20)
                ),
                viewModel: viewModel
            )
        ]
    )
    
    // MARK: - Initializers
    init(currentPath: SolanaSDK.DerivablePath) {
        self.initPath = currentPath
        viewModel = DerivablePathsViewModel(currentPath: currentPath)
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.reload()
    }
    
    override func setUp() {
        super.setUp()
        view.addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges()
        collectionView.delegate = self
    }
    
    func beCollectionView(collectionView: BECollectionView, didSelect item: AnyHashable) {
        guard let path = item as? SelectableDerivablePath else {return}
        var paths = viewModel.data
        for i in 0..<paths.count {
            paths[i].isSelected = false
            if paths[i].path == path.path {
                paths[i].isSelected = true
            }
        }
        viewModel.overrideData(by: paths)
        completion?(path.path)
    }
}
