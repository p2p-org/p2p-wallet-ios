//
//  ReceiveTokenVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import DiffableDataSources
import Action
import IBPCollectionViewCompositionalLayout

class ReceiveTokenVC: WLBottomSheet {
    // MARK: - Properties
    override var padding: UIEdgeInsets {UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)}
    
    var dataSource: CollectionViewDiffableDataSource<String, Wallet>!
    
    // MARK: - Subviews
    lazy var collectionView: BaseCollectionView = {
        let collectionView = BaseCollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.configureForAutoLayout()
        collectionView.autoSetDimension(.height, toSize: 315)
        collectionView.registerCells([ReceiveTokenCell.self])
        collectionView.alwaysBounceVertical = false
        return collectionView
    }()
    public lazy var pageControl: UIPageControl = {
        let pc = UIPageControl(forAutoLayout: ())
//        pc.addTarget(self, action: #selector(pageControlDidChange), for: .valueChanged)
        pc.isUserInteractionEnabled = false
        pc.pageIndicatorTintColor = .a4a4a4
        pc.currentPageIndicatorTintColor = .textBlack
        return pc
    }()
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        interactor = nil
        view.removeGestureRecognizer(panGestureRecognizer!)
        
        view.layoutIfNeeded()
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    override func setUp() {
        super.setUp()
        title = L10n.receiveToken
        stackView.addArrangedSubview(collectionView)
        stackView.addArrangedSubview(pageControl)
        
        dataSource = CollectionViewDiffableDataSource<String, Wallet>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: Wallet) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ReceiveTokenCell.self), for: indexPath) as? ReceiveTokenCell
            cell?.setUp(wallet: item)
            cell?.copyButton.rx.action = CocoaAction {
                UIPasteboard.general.string = item.pubkey
                UIApplication.shared.showDone(L10n.copiedToClipboard)
                return .just(())
            }
            cell?.shareButton.rx.action = CocoaAction {
                let vc = UIActivityViewController(activityItems: [item.pubkey!], applicationActivities: nil)
                self.present(vc, animated: true, completion: nil)
                return .just(())
            }
            return cell ?? UICollectionViewCell()
        }
    }
    
    override func bind() {
        super.bind()
        WalletsVM.ofCurrentUser.state
            .subscribe(onNext: {state in
                switch state {
                case .loaded(let wallets):
                    // config snapshot
                    var snapshot = DiffableDataSourceSnapshot<String, Wallet>()
                    let section = ""
                    snapshot.appendSections([section])
                    snapshot.appendItems(wallets, toSection: section)
                    self.dataSource.apply(snapshot)
                    
                    // config pagecontrol
                    self.pageControl.numberOfPages = wallets.count
                default:
                    // TODO:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
    
    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { (_: Int, _: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(335), heightDimension: .absolute(315))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 10
            section.orthogonalScrollingBehavior = .groupPagingCentered
            section.visibleItemsInvalidationHandler = { [weak self] _, _, _ in
                if let visibleRows = self?.collectionView.indexPathsForVisibleItems.map({$0.row})
                {
                    var currentPage: Int = 0
                    
                    switch visibleRows.count {
                    case 1:
                        currentPage = visibleRows.first!
                    case 2:
                        if visibleRows.contains(0) {
                            // at the begining of the collectionView
                            currentPage = visibleRows.min()!
                        } else {
                            // at the end of the collectionView
                            currentPage = visibleRows.max()!
                        }
                    case 3:
                        let rowsSum = visibleRows.reduce(0, +)
                        currentPage = rowsSum / visibleRows.count
                    default:
                        break
                    }
                    self?.pageControl.currentPage = currentPage
                }
            }
            return section
        }
    }
    
//    @objc func pageControlDidChange() {
//        guard pageControl.currentPage < collectionView.numberOfItems(inSection: 0) else {return}
//        collectionView.scrollToItem(at: IndexPath(row: pageControl.currentPage, section: 0), at: .centeredHorizontally, animated: true)
//    }
}
