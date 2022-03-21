//
//  InvestmentsRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import UIKit

class InvestmentsRootView: BEView {
    // MARK: - Constants

    // MARK: - Properties

    let viewModel: InvestmentsViewModel

    // MARK: - Subviews

    lazy var collectionView = InvestmentsCollectionView(
        newsViewModel: viewModel.newsViewModel,
        defisViewModel: viewModel.defisViewModel
    )

    // MARK: - Initializers

    init(viewModel: InvestmentsViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }

    // MARK: - Methods

    override func commonInit() {
        super.commonInit()
        viewModel.reload()
        layout()
        bind()
    }

    // MARK: - Layout

    private func layout() {
        addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges()
    }

    private func bind() {}
}
