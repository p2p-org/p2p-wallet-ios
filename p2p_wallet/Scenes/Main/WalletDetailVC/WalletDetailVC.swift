//
//  WalletDetailVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import Action

private class _WalletDetailVC: CollectionVC<Transaction> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .embeded }
    var graphVM: WalletGraphVM { (viewModel as! ViewModel).graphVM }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        let vm = viewModel as! ViewModel
        title = vm.wallet.name
        view.backgroundColor = .vcBackground
        
        collectionView.contentInset = collectionView.contentInset.modifying(dBottom: 71)
    }
    
    // MARK: - Layout
    override var sections: [CollectionViewSection] {
        [CollectionViewSection(
            header: CollectionViewSection.Header(
                viewClass: WDVCSectionHeaderView.self,
                title: L10n.activities
            ),
            cellType: TransactionCell.self,
            interGroupSpacing: 2,
            itemHeight: .absolute(71)
        )]
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        let vm = viewModel as! ViewModel
        if indexPath.section == 0 {
            let header = header as! WDVCSectionHeaderView
            header.setUp(wallet: vm.wallet)
            header.lineChartView
                .subscribed(to: graphVM)
                .disposed(by: disposeBag)
            header.chartPicker.delegate = self
            header.scanQrCodeAction = CocoaAction {
                let vc = ReceiveTokenVC(wallets: [vm.wallet])
                self.present(vc, animated: true, completion: nil)
                return .just(())
            }
        }
        return header
    }
    
    override func itemDidSelect(_ item: Transaction) {
        let vc = TransactionInfoVC(transaction: item)
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    func createButton(title: String) -> UIView {
        let view = UIView(height: 56, backgroundColor: .textBlack)
        let label = UILabel(text: title, textSize: 15.adaptiveWidth, weight: .semibold, textColor: .textWhite, numberOfLines: 0, textAlignment: .center)
        view.addSubview(label)
        label.autoPinEdge(toSuperviewEdge: .top)
        label.autoPinEdge(toSuperviewEdge: .bottom)
        label.autoPinEdge(toSuperviewEdge: .leading, withInset: 16.adaptiveWidth)
        label.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16.adaptiveWidth)
        return view
    }
}

extension _WalletDetailVC {
    class ViewModel: WalletTransactionsVM {
        let graphVM: WalletGraphVM
        
        override init(solanaSDK: SolanaSDK, walletsVM: WalletsVM, wallet: Wallet) {
            graphVM = WalletGraphVM(wallet: wallet)
            super.init(solanaSDK: solanaSDK, walletsVM: walletsVM, wallet: wallet)
        }
        
        override func reload() {
            graphVM.reload()
            super.reload()
        }
    }
}

extension _WalletDetailVC: HorizontalPickerDelegate {
    func picker(_ picker: HorizontalPicker, didSelectOptionAtIndex index: Int) {
        guard index < Period.allCases.count else {return}
        graphVM.period = Period.allCases[index]
        graphVM.reload()
    }
}
