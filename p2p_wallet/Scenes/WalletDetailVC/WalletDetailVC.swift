//
//  WalletDetailVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import DiffableDataSources
import Action

class WalletDetailVC: CollectionVC<Transaction, TransactionCell> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .normal(backgroundColor: .vcBackground) }
    let wallet: Wallet
    var graphVM: WalletGraphVM { (viewModel as! ViewModel).graphVM }
    
    lazy var buttonsView: UIView = {
        let view = UIView(forAutoLayout: ())
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        let buttonsStackView = UIStackView(
            axis: .horizontal,
            spacing: 2,
            alignment: .fill,
            distribution: .fillEqually,
            arrangedSubviews: [
                self.createButton(title: L10n.send)
                    .onTap(self, action: #selector(buttonSendDidTouch)),
                self.createButton(title: L10n.swap)
                    .onTap(self, action: #selector(buttonSwapDidTouch))
            ]
        )
        view.addSubview(buttonsStackView)
        buttonsStackView.autoPinEdgesToSuperviewEdges()
        return view
    }()
    
    // MARK: - Initializer
    init(wallet: Wallet) {
        self.wallet = wallet
        super.init(viewModel: ViewModel(wallet: wallet))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        title = wallet.name
        view.backgroundColor = .vcBackground
        
        collectionView.contentInset = collectionView.contentInset.modifying(dBottom: 71)
        
        view.addSubview(buttonsView)
        buttonsView.autoAlignAxis(toSuperviewAxis: .vertical)
        buttonsView.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 30)
    }
    
    override func bind() {
        super.bind()
        
        // manage show/hide buttons
        collectionView.rx.willBeginDecelerating
            .subscribe(onNext: {
                let actualPosition = self.collectionView.panGestureRecognizer.translation(in: self.view)
                let constraint = self.buttonsView.constraintToSuperviewWithAttribute(.bottom)
                if actualPosition.y > 0 {
                    // Dragging down
                    constraint?.constant = -30
                    self.buttonsView.isHidden = false
                } else{
                    // Dragging up
                    constraint?.constant = 30
                    self.buttonsView.isHidden = true
                }
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [Section(
            headerViewClass: WDVCSectionHeaderView.self,
            headerTitle: L10n.activities,
            interGroupSpacing: 2,
            itemHeight: .absolute(71)
        )]
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        if indexPath.section == 0 {
            let header = header as! WDVCSectionHeaderView
            header.setUp(wallet: wallet)
            header.lineChartView
                .subscribed(to: graphVM)
                .disposed(by: disposeBag)
            header.chartPicker.delegate = self
            header.scanQrCodeAction = CocoaAction {
                let vc = ReceiveTokenVC(filteredSymbols: [self.wallet.symbol])
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
    
    // MARK: - Actions
    @objc func buttonSendDidTouch() {
        let vc = SendTokenVC(wallets: WalletsVM.ofCurrentUser.data, initialSymbol: wallet.symbol)
        self.show(vc, sender: nil)
    }
    
    @objc func buttonSwapDidTouch() {
        // TODO: - Swap
        let vc = SwapTokenVC(wallets: WalletsVM.ofCurrentUser.data)
        self.show(vc, sender: nil)
    }
}

extension WalletDetailVC: HorizontalPickerDelegate {
    func picker(_ picker: HorizontalPicker, didSelectOptionAtIndex index: Int) {
        guard index < Period.allCases.count else {return}
        graphVM.period = Period.allCases[index]
        graphVM.reload()
    }
}
