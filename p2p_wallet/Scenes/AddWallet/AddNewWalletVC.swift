//
//  ChooseNewWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/11/2020.
//

import Foundation

class AddNewWalletVC: WLModalWrapperVC {
    override var padding: UIEdgeInsets {.init(x: 0, y: .defaultPadding)}
    lazy var searchBar: BESearchBar = {
        let searchBar = BESearchBar(fixedHeight: 36, cornerRadius: 12)
        searchBar.textFieldBgColor = .lightGrayBackground
        searchBar.magnifyingIconSize = 24
        searchBar.magnifyingIconImageView.image = .search
        searchBar.magnifyingIconImageView.tintColor = .textBlack
        searchBar.leftViewWidth = 24+10+10
        searchBar.placeholder = L10n.searchToken
        searchBar.delegate = self
        searchBar.cancelButton.setTitleColor(.h5887ff, for: .normal)
        searchBar.setUpTextField(autocorrectionType: .no, autocapitalizationType: UITextAutocapitalizationType.none, spellCheckingType: .no)
        return searchBar
    }()
    
    init() {
        super.init(wrapped: _AddNewWalletVC())
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    override func setUp() {
        super.setUp()
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.addToken, textSize: 17, weight: .semibold)
                    .padding(.init(x: 20, y: 0)),
                UIButton(label: L10n.close, labelFont: .systemFont(ofSize: 17, weight: .medium), textColor: .h5887ff)
                    .onTap(self, action: #selector(back))
                    .padding(.init(x: 20, y: 0))
            ]),
            BEStackViewSpacing.defaultPadding,
            UIView.separator(height: 1, color: .separator),
            BEStackViewSpacing.defaultPadding,
            searchBar
                .padding(.init(x: .defaultPadding, y: 0))
        ])
        
    }
}

extension AddNewWalletVC: BESearchBarDelegate {
    func beSearchBar(_ searchBar: BESearchBar, searchWithKeyword keyword: String) {
        let vm = (self.vc as! _AddNewWalletVC).viewModel as! _AddNewWalletVM
        vm.offlineSearch(query: keyword)
    }
    
    func beSearchBarDidBeginSearching(_ searchBar: BESearchBar) {
        
    }
    
    func beSearchBarDidEndSearching(_ searchBar: BESearchBar) {
        
    }
    
    func beSearchBarDidCancelSearching(_ searchBar: BESearchBar) {
        
    }
}

extension AddNewWalletVC: UIViewControllerTransitioningDelegate {
    class PresentationController: CustomHeightPresentationController {
        override func containerViewDidLayoutSubviews() {
            super.containerViewDidLayoutSubviews()
            presentedView?.roundCorners([.topLeft, .topRight], radius: 20)
        }
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(height: {
            if UIDevice.current.userInterfaceIdiom == .phone, UIDevice.current.orientation == .landscapeLeft ||
                UIDevice.current.orientation == .landscapeRight
            {
                return UIScreen.main.bounds.height
            }
            return UIScreen.main.bounds.height - 85.adaptiveHeight
        }, presentedViewController: presented, presenting: presenting)
    }
}
