//
//  DerivableAccountsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import Foundation
import BECollectionView

final class DerivableAccountsVC: BaseVC, DerivablePathsVCDelegate {
    // MARK: - Properties
    private let viewModel: DerivableAccountsViewModel
    private let analyticsManager: AnalyticsManagerType
    
    // MARK: - Subviews
    private lazy var headerView = UIStackView(axis: .vertical, spacing: 20, alignment: .leading, distribution: .fill) {
        UIImageView(width: 36, height: 36, image: .backSquare)
            .onTap(self, action: #selector(back))
        BEStackViewSpacing(30)
        UILabel(text: L10n.derivableAccounts, textSize: 27, weight: .bold, numberOfLines: 0)
        UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill) {
            derivationPathLabel
            UIImageView(width: 10, height: 8, image: .downArrow, tintColor: .a3a5ba)
        }
            .padding(.init(all: 18), backgroundColor: .grayPanel, cornerRadius: 12)
            .onTap(viewModel, action: #selector(DerivableAccountsViewModel.selectDerivationPath))
    }
    
    private lazy var derivationPathLabel = UILabel(textSize: 17, weight: .semibold)
    private lazy var accountsCollectionView: BEStaticSectionsCollectionView = {
        let collectionView = BEStaticSectionsCollectionView(
            sections: [
                .init(
                    index: 0,
                    layout: .init(
                        cellType: DerivableAccountCell.self,
                        itemHeight: .estimated(75)
                    ),
                    viewModel: viewModel.output.accountsViewModel
                )
            ]
        )
        collectionView.isUserInteractionEnabled = false
        collectionView.collectionView.contentInset.modify(dTop: 15, dBottom: 15)
        return collectionView
    }()
    
    // MARK: - Methods
    init(viewModel: DerivableAccountsViewModel, analyticsManager: AnalyticsManagerType) {
        self.viewModel = viewModel
        self.analyticsManager = analyticsManager
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.input.derivationPath.onNext(.default)
        analyticsManager.log(event: .recoveryDerivableAccountsOpen)
    }
    
    override func setUp() {
        super.setUp()
        view.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .init(all: 20), excludingEdge: .bottom)
        
        let separator = UIView.defaultSeparator()
        view.addSubview(separator)
        separator.autoPinEdge(.top, to: .bottom, of: headerView, withOffset: 16)
        separator.autoPinEdge(toSuperviewEdge: .leading)
        separator.autoPinEdge(toSuperviewEdge: .trailing)
        
        view.addSubview(accountsCollectionView)
        accountsCollectionView.autoPinEdge(.top, to: .bottom, of: separator)
        accountsCollectionView.autoPinEdge(toSuperviewSafeArea: .leading)
        accountsCollectionView.autoPinEdge(toSuperviewSafeArea: .trailing)
        
        let separator2 = UIView.defaultSeparator()
        view.addSubview(separator2)
        separator2.autoPinEdge(.top, to: .bottom, of: accountsCollectionView)
        separator2.autoPinEdge(toSuperviewEdge: .leading)
        separator2.autoPinEdge(toSuperviewEdge: .trailing)
        
        let button = WLButton.stepButton(type: .black, label: L10n.restore)
            .onTap(self, action: #selector(dismissAndRestore))
        view.addSubview(button)
        button.autoPinEdge(.top, to: .bottom, of: separator2, withOffset: 16)
        button.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
        button.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
        button.autoPinEdge(toSuperviewEdge: .bottom, withInset: 30)
    }
    
    override func bind() {
        super.bind()
        // Bind input
        
        // Bind output
        viewModel.output.navigatingScene
            .drive(onNext: {[weak self] in self?.navigate(to: $0)})
            .disposed(by: disposeBag)
        
        viewModel.output.selectedDerivationPath
            .map {$0?.rawValue}
            .asDriver(onErrorJustReturn: nil)
            .drive(derivationPathLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    private func navigate(to scene: DerivableAccountsNavigatableScene) {
        switch scene {
        case .selectDerivationPath:
            guard let path = viewModel.output.selectedDerivationPath.value else {return}
            let vc = DerivablePathsVC(currentPath: path)
            vc.delegate = self
            present(vc, animated: true, completion: nil)
        }
    }
    
    func derivablePathsVC(_ vc: DerivablePathsVC, didSelectPath path: SolanaSDK.DerivablePath) {
        viewModel.input.derivationPath.onNext(path)
        analyticsManager.log(event: .recoveryDerivableAccountsPathSelected(path: path.rawValue))
        vc.dismiss(animated: true, completion: nil)
    }
    
    @objc func dismissAndRestore() {
        self.dismiss(animated: true) { [weak self] in
            self?.viewModel.restoreAccount()
        }
    }
}
