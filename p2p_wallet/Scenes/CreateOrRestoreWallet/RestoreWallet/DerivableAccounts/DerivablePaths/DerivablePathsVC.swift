//
//  DerivationPathsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import Foundation
import BECollectionView

protocol DerivablePathsVCDelegate: AnyObject {
    func derivablePathsVC(_ vc: DerivablePathsVC, didSelectPath path: SolanaSDK.DerivablePath)
}

class DerivablePathsVC: BaseVC, BECollectionViewDelegate {
    // MARK: - Properties
    private let initPath: SolanaSDK.DerivablePath
    private let viewModel: DerivablePathsViewModel
    weak var delegate: DerivablePathsVCDelegate?
    
    // MARK: - Subviews
    private lazy var collectionView = BECollectionView(
        sections: [
            .init(
                index: 0,
                layout: .init(
                    cellType: DerivablePathCell.self,
                    itemHeight: .estimated(64)
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
        delegate?.derivablePathsVC(self, didSelectPath: path.path)
    }
}
