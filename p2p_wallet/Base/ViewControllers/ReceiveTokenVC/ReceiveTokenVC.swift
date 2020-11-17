//
//  ReceiveTokenVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import DiffableDataSources

class ReceiveTokenVC: WLBottomSheet {
    
    lazy var collectionView: BaseCollectionView = {
        let collectionView = BaseCollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.configureForAutoLayout()
        collectionView.autoSetDimension(.height, toSize: 315)
        collectionView.registerCells([ReceiveTokenCell.self])
        return collectionView
    }()
    var dataSource: CollectionViewDiffableDataSource<String, Wallet>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        interactor = nil
        view.removeGestureRecognizer(panGestureRecognizer!)
    }
    
    override func setUp() {
        super.setUp()
        title = L10n.receiveToken
        stackView.addArrangedSubview(collectionView)
        
        dataSource = CollectionViewDiffableDataSource<String, Wallet>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: Wallet) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ReceiveTokenCell.self), for: indexPath) as? ReceiveTokenCell
            cell?.setUp(wallet: item)
            return cell ?? UICollectionViewCell()
        }
    }
    
    override func bind() {
        super.bind()
        WalletVM.ofCurrentUser.state
            .subscribe(onNext: {state in
                switch state {
                case .loaded(let wallets):
                    var snapshot = DiffableDataSourceSnapshot<String, Wallet>()
                    let section = ""
                    snapshot.appendSections([section])
                    snapshot.appendItems(wallets, toSection: section)
                    self.dataSource.apply(snapshot)
                default:
                    // TODO:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
    
    func createLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        return UICollectionViewCompositionalLayout(sectionProvider: { (_: Int, _: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(335), heightDimension: .absolute(315))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 10
            return section
        }, configuration: config)
    }
}
