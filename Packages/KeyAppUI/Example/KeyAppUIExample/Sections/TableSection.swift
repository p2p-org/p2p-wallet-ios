import BEPureLayout
import Foundation
import KeyAppUI
import SkeletonView
import UIKit

class TableSection: BECompositionView {
    
    override func build() -> UIView {
        BEVStack(spacing: 15) {
            UILabel(text: "Cells", textSize: 22).padding(.init(only: .top, inset: 20))
            TextButton(
                title: "Open Cells",
                style: .primary,
                size: .large
            )
        }   
    }
}

class TableViewController: UICollectionViewController, SkeletonCollectionViewDataSource {
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        
        let flowLayout = SeparatorCollectionViewFlowLayout()
        flowLayout.estimatedItemSize = .init(width: UIScreen.main.bounds.width, height: 70)
        flowLayout.sectionInset = .zero
        flowLayout.minimumLineSpacing = 0.5
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.headerReferenceSize = .init(width: UIScreen.main.bounds.width, height: 45)

        let collection = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: flowLayout)
        collection.isSkeletonable = true
        collection.delegate = self
        collection.dataSource = self
        collection.register(BaseCell.self, forCellWithReuseIdentifier: "cell")
        collection.register(SkeletonCell.self, forCellWithReuseIdentifier: "cell1")
        
        collection.register(SectionHeader.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: "SectionHeader")

        let view = UIView()
        self.view = view
        view.addSubview(collection)
        collection.autoPinEdgesToSuperviewEdges()

        collection.showAnimatedSkeleton(usingColor: Asset.Colors.rain.color, transition: .crossDissolve(0.2))
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            collection.hideSkeleton()
        }
        
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { section == 0 ? 10 : 36 }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: BaseCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! BaseCell? ?? BaseCell(frame: .zero)
        if indexPath.section == 1 {
            cell.configure(with: cellItem(forRow: indexPath.row)!)
        } else {
            cell.configure(with: financialCellItem(forRow: indexPath.row)!)
        }
        cell.contentView.isSkeletonable = true
        return cell
    }
    
    // MARK: -
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "cell1"
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, skeletonCellForItemAt indexPath: IndexPath) -> UICollectionViewCell? {
        skeletonView.dequeueReusableCell(withReuseIdentifier: "cell1", for: indexPath)
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, prepareCellForSkeleton cell: UICollectionViewCell, at indexPath: IndexPath) {
        (cell as! SkeletonCell).configure(with: skeletonCellItem(forRow: 0)!)
        cell.makeSkeletonable()
    }
    
    // MARK: -
    
    func skeletonCellItem(forRow: Int) -> BaseCellItem? {
        let rightItem = BaseCellRightViewItem(
            text: " ",
            subtext: nil,
            image: nil,
            isChevronVisible: false,
            badge: nil,
            yellowBadge: nil,
            checkbox: nil,
            switch: nil
        )
        
        let item = BaseCellItem(
            image: .init(image: Asset.Icons.send.image, statusImage: nil),
            title: "Send",
            subtitle: "23.8112 SOL",
            subtitle2: nil,
            rightView: rightItem
        )
        return item
    }
    
    func financialCellItem(forRow: Int) -> BaseCellItem? {
        let rightItem = BaseCellRightViewItem(
            text: nil,
            subtext: nil,
            image: nil,
            isChevronVisible: false,
            badge: nil,
            yellowBadge: nil,
            checkbox: nil,
            switch: nil
        )
        
        var item = BaseCellItem(
            image: .init(image: Asset.Icons.send.image, statusImage: nil),
            title: "Send",
            subtitle: "23.8112 SOL",
            subtitle2: nil,
            rightView: rightItem
        )
        item.rightView?.subtext = "23.8112 SOL"

        switch forRow {
        case 0:
            item.image = .init(
                image: UIImage(named: "coinImage")!,
                statusImage: UIImage(named: "statusIcon")
            )
        case 1:
            item.image = .init(
                image: UIImage(named: "coinImage")!,
                secondImage: UIImage(named: "coinImage2")!
            )
            item.rightView?.isChevronVisible = true
        case 2:
            item.image = .init(
                image: UIImage(named: "coinImage")!
            )
            item.rightView?.subtext = "23.8112 SOL"
            item.rightView?.isCheckmark = true
        case 3:
            item.image = .init(
                image: UIImage(named: "coinImage2")!
            )
            item.rightView?.subtext = "23.8112 SOL"
            item.rightView?.isChevronVisible = true
            item.image?.statusImage = UIImage(named: "renStatus")
        case 4:
            item.image = .init(
                image: UIImage(named: "coinImage")!
            )
            item.rightView?.subtext = "23.8112 SOL"
            item.rightView?.image = UIImage(named: "info")!
        case 5:
            item.image = .init(
                image: UIImage(named: "coinImage2")!
            )
            item.rightView?.image = UIImage(named: "info")!
        case 6:
            item.image = .init(
                image: UIImage(named: "coinImage")!
            )
            item.image?.statusImage = nil
        case 7:
            item.rightView?.text = "$190.91"
            item.rightView?.subtext = "23.811 SOL"
        case 8:
            item.rightView?.text = "$190.91"
        case 9:
            item.rightView?.subtext = "23.811 SOL"
        default: break
        }
        return item
    }
    
    func cellItem(forRow: Int) -> BaseCellItem? {
        let rightItem = BaseCellRightViewItem()
        var item = BaseCellItem(
            title: "Send",
            subtitle: "23.8112 SOL",
            rightView: rightItem
        )
        
        switch forRow {
        case 0:
            item.rightView?.`switch` = true
        case 1:
            item.rightView?.isChevronVisible = true
        case 2:
            item.rightView?.subtext = "23.8112 SOL"
            item.rightView?.isCheckmark = true
        case 3:
            item.rightView?.subtext = "23.8112 SOL"
            item.rightView?.isChevronVisible = true
        case 4:
            item.rightView?.subtext = "23.8112 SOL"
            item.rightView?.image = UIImage(named: "info")!
        case 5:
            item.rightView?.image = UIImage(named: "info")!
        case 6:
            item.rightView?.checkbox = false
        case 7:
            item.rightView?.text = "$190.91"
            item.rightView?.subtext = "23.811 SOL"
        case 8:
            item.rightView?.text = "$190.91"
        case 9:
            item.rightView?.subtext = "23.811 SOL"
        case 11:
            item.rightView?.image = nil
            item.rightView?.badge = "9"
            item.rightView?.isChevronVisible = true
        case 12:
            item.rightView?.badge = "9"
            item.rightView?.subtext = "news"
        case 13:
            item.title = "Send"
            item.subtitle2 = "23.811 SOL\n23.811 SOL"
            item.rightView?.subtext = "23.8112 SOL"
            item.rightView?.isCheckmark = true
        case 14:
            item.title = "Send"
            item.subtitle = nil
            item.subtitle2 = "23.811 SOL\n23.811 SOL"
        case 15:
            item.title = "Send"
            item.subtitle = nil
            item.subtitle2 = "23.811 SOL\n23.811 SOL"
            item.rightView?.badge = "9"
            item.rightView?.isChevronVisible = true
            
        case 16:
            item.title = "Send"
            item.subtitle = nil
            item.subtitle2 = "23.811 SOL\n23.811 SOL"
            item.rightView?.isCheckmark = true
            
        case 17:
            item.title = "Send"
            item.subtitle = nil
            item.subtitle2 = "23.811 SOL\n23.811 SOL"
            item.rightView?.badge = "9"
            item.rightView?.subtext = "news"
            
        case 18:
            item.title = "Send"
            item.subtitle = "23.811 SOL"
            item.subtitle2 = "23.811 SOL"
            item.rightView?.isChevronVisible = true
            
        case 19:
            item.title = "Send"
            item.subtitle = "23.811 SOL"
            item.subtitle2 = "23.811 SOL"
            item.rightView?.isChevronVisible = true
            item.rightView?.subtext = "23.8112 SOL"
            
        case 20:
            item.title = "Send"
            item.subtitle = "23.811 SOL"
            item.subtitle2 = "23.811 SOL"
            item.rightView?.image = UIImage(named: "info")!
            
        case 21:
            item.title = "Send"
            item.subtitle = "23.811 SOL"
            item.subtitle2 = "23.811 SOL"
            item.rightView?.text = "$190.91"
            item.rightView?.subtext = "23.811 SOL"
            
        case 22:
            item.title = "Send"
            item.subtitle = "23.811 SOL"
            item.subtitle2 = "23.811 SOL"
            item.rightView?.subtext = "23.811 SOL"
            
        case 23:
            item.title = "Send"
            item.subtitle = "23.811 SOL"
            item.subtitle2 = "23.811 SOL"
            item.rightView = nil
            
        case 24:
            item.title = "Send"
            item.subtitle = "23.811 SOL"
            item.subtitle2 = "23.811 SOL"
            item.rightView?.isCheckmark = true
            
        case 25:
            item.title = "Send"
            item.subtitle = nil
            item.subtitle2 = "23.811 SOL\n23.811 SOL"
            item.rightView?.yellowBadge = "+$3.75"
            item.rightView?.text = "$192.21"
            
        case 26:
            item.title = "Send"
            item.subtitle = nil
            item.subtitle2 = "23.811 SOL"
            item.rightView?.isChevronVisible = true
            
        case 27:
            item.image = .init(image: UIImage(named: "heart")!, imageSize: .init(width: 24, height: 24))
            item.title = "Send"
            item.subtitle = nil
            item.subtitle2 = "23.811 SOL"
            item.rightView?.isChevronVisible = true
            
        case 28:
            item.image = .init(image: UIImage(named: "heart")!, imageSize: .init(width: 24, height: 24))
            item.rightView?.subtext = "23.8112 SOL"
            item.rightView?.isCheckmark = true
        case 29:
            item.image = .init(image: UIImage(named: "heart")!, imageSize: .init(width: 24, height: 24))
            item.rightView?.subtext = "23.8112 SOL"
            item.rightView?.isChevronVisible = true
        case 30:
            item.image = .init(image: UIImage(named: "heart")!, imageSize: .init(width: 24, height: 24))
            item.rightView?.subtext = "23.8112 SOL"
            item.rightView?.image = UIImage(named: "info")!
        case 31:
            item.image = .init(image: UIImage(named: "heart")!, imageSize: .init(width: 24, height: 24))
            item.rightView?.image = UIImage(named: "info")!
        case 32:
            item.rightView?.image = UIImage(named: "info")!
            item.title = "Send"
            item.image = .init(image: UIImage(named: "heart")!, imageSize: .init(width: 24, height: 24))
            item.subtitle = nil
            item.subtitle2 = nil
        case 33:
            item.rightView?.yellowBadge = "+$3.75"
            item.title = "Send"
            item.subtitle = nil
            item.subtitle2 = nil
        case 34:
            item.rightView?.image = UIImage(named: "info")!.withTintColor(Asset.Colors.night.color, renderingMode: .alwaysOriginal)
            item.title = "Send"
            item.rightView?.isChevronVisible = true
            item.subtitle = nil
            item.subtitle2 = nil
            item.rightView?.text = "Text"
        case 35:
            item.rightView?.buttonTitle = "Button Title"
            item.title = "Send"
            item.subtitle = nil
            item.subtitle2 = nil

        default: break
        }
        
        return item
    }
    
    public override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as? SectionHeader {
            sectionHeader.configure(text: indexPath.section == 0 ? "HIDDEN TOKENS" : "CELLS", expandDirection: .bottom)
            return sectionHeader
        }
        return UICollectionReusableView()
    }
}

public class CollectionSeparatorView: UICollectionReusableView {
    
    public static let reusableIdentifier = "CollectionSeparatorView"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .gray
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        frame = layoutAttributes.frame
    }
}

public class SeparatorCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    private var indexPathsToInsert: [IndexPath] = []
    private var indexPathsToDelete: [IndexPath] = []
    
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        setup()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    
    public override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        
        for item in updateItems {
            switch item.updateAction {
            case .delete:
                if let indexPath = item.indexPathBeforeUpdate {
                    indexPathsToDelete.append(indexPath)
                }
                
            case .insert:
                if let indexPath = item.indexPathAfterUpdate {
                    indexPathsToInsert.append(indexPath)
                }
                
            default:
                break
            }
        }
    }
    
    
    public override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        
        indexPathsToDelete.removeAll()
        indexPathsToInsert.removeAll()
    }
    
    
    public override func indexPathsToDeleteForDecorationView(ofKind elementKind: String) -> [IndexPath] {
        return indexPathsToDelete
    }
    
    
    public override func indexPathsToInsertForDecorationView(ofKind elementKind: String) -> [IndexPath] {
        return indexPathsToInsert
    }
    
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutAttributesArray = super.layoutAttributesForElements(in: rect) else { return nil }
        
        var decorationAttributes: [UICollectionViewLayoutAttributes] = []
        for layoutAttributes in layoutAttributesArray {
            
            let indexPath = layoutAttributes.indexPath
            if let separatorAttributes = layoutAttributesForDecorationView(ofKind: CollectionSeparatorView.reusableIdentifier, at: indexPath) {
                if rect.intersects(separatorAttributes.frame) {
                    decorationAttributes.append(separatorAttributes)
                }
            }
        }
        
        let allAttributes = layoutAttributesArray + decorationAttributes
        return allAttributes
    }
    
    public
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let cellAttributes = layoutAttributesForItem(at: indexPath) else {
            return createAttributesForMyDecoration(at: indexPath)
        }
        return layoutAttributesForMyDecoratinoView(at: indexPath, for: cellAttributes.frame, state: .normal)
    }
    
    public
    override func initialLayoutAttributesForAppearingDecorationElement(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let cellAttributes = initialLayoutAttributesForAppearingItem(at: indexPath) else {
            return createAttributesForMyDecoration(at: indexPath)
        }
        return layoutAttributesForMyDecoratinoView(at: indexPath, for: cellAttributes.frame, state: .initial)
    }
    
    public
    override func finalLayoutAttributesForDisappearingDecorationElement(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let cellAttributes = finalLayoutAttributesForDisappearingItem(at: indexPath) else {
            return createAttributesForMyDecoration(at: indexPath)
        }
        return layoutAttributesForMyDecoratinoView(at: indexPath, for: cellAttributes.frame, state: .final)
    }
    
    
    // MARK: - privates
    
    private enum State {
        case initial
        case normal
        case final
    }
    
    private func setup() {
        register(CollectionSeparatorView.self, forDecorationViewOfKind: CollectionSeparatorView.reusableIdentifier)
    }
    
    private func createAttributesForMyDecoration(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        return UICollectionViewLayoutAttributes(forDecorationViewOfKind: CollectionSeparatorView.reusableIdentifier, with: indexPath)
    }
    
    private func layoutAttributesForMyDecoratinoView(at indexPath: IndexPath, for cellFrame: CGRect, state: State) -> UICollectionViewLayoutAttributes? {
        
        guard let rect = collectionView?.bounds else {
            return nil
        }
        
        //Add separator for every row except the first
        guard indexPath.item > 0 else {
            return nil
        }
        
        let separatorAttributes = createAttributesForMyDecoration(at: indexPath)
        separatorAttributes.alpha = 1.0
        separatorAttributes.isHidden = false
        
        let firstCellInRow = cellFrame.origin.x < cellFrame.width
        if firstCellInRow {
            // horizontal line
            separatorAttributes.frame = CGRect(x: rect.minX, y: cellFrame.origin.y - minimumLineSpacing, width: rect.width, height: minimumLineSpacing)
            separatorAttributes.zIndex = 1000
            
        } else {
            // vertical line
            separatorAttributes.frame = CGRect(x: cellFrame.origin.x - minimumInteritemSpacing, y: cellFrame.origin.y, width: minimumInteritemSpacing, height: cellFrame.height)
            separatorAttributes.zIndex = 1000
        }
        
        // Sync the decorator animation with the cell animation in order to avoid blinkining
        switch state {
        case .normal:
            separatorAttributes.alpha = 1
        default:
            separatorAttributes.alpha = 0.1
        }
        
        return separatorAttributes
    }
}

public class SkeletonCell: BaseCell {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
