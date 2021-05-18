//
//  DerivableAccountsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import Foundation

final class DerivableAccountsVC: BaseVC {
    // MARK: - Properties
    private let viewModel: DerivableAccountsViewModel
    
    // MARK: - Subviews
    private lazy var headerView = UIStackView(axis: .vertical, spacing: 20, alignment: .leading, distribution: .fill) {
        UIImageView(width: 36, height: 36, image: .backButtonLight)
            .onTap(self, action: #selector(back))
        BEStackViewSpacing(30)
        UILabel(text: L10n.derivableAccounts, textSize: 27, weight: .bold, numberOfLines: 0)
        UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill) {
            derivationPathLabel
            UIImageView(width: 10, height: 8, image: .downArrow, tintColor: .a3a5ba)
        }
            .padding(.init(all: 18), backgroundColor: .f6f6f8, cornerRadius: 12)
            .onTap(viewModel, action: #selector(DerivableAccountsViewModel.selectDerivationPath))
    }
    
    private lazy var derivationPathLabel = UILabel(textSize: 17, weight: .semibold)
    
    // MARK: - Methods
    init(viewModel: DerivableAccountsViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func setUp() {
        super.setUp()
        view.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .init(all: 20), excludingEdge: .bottom)
        
        let separator = UIView.separator(height: 1, color: .separator)
        view.addSubview(separator)
        separator.autoPinEdge(.top, to: .bottom, of: headerView, withOffset: 16)
        separator.autoPinEdge(toSuperviewEdge: .leading)
        separator.autoPinEdge(toSuperviewEdge: .trailing)
        
        // TODO: - List view
    }
    
    override func bind() {
        super.bind()
        // Bind input
        
        // Bind output
        viewModel.output.navigatingScene
            .drive(onNext: {[weak self] in self?.navigate(to: $0)})
            .disposed(by: disposeBag)
        
        viewModel.output.selectedDerivationPath
            .map {$0.rawValue}
            .drive(derivationPathLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    private func navigate(to scene: DerivableAccountsNavigatableScene) {
        switch scene {
        case .selectDerivationPath:
            let vc = BaseVC()
            present(vc, animated: true, completion: nil)
        }
    }
}
