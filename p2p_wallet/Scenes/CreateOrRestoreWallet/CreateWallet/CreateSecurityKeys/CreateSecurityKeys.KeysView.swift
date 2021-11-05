//
// Created by Giang Long Tran on 04.11.21.
//

import Foundation
import BECollectionView
import RxSwift
import RxCocoa

extension CreateSecurityKeys {
    private class Cell: UICollectionViewCell {
        var key: String = "" {
            didSet {
                textLabel.text = key
            }
        }
        
        var index: Int = 0 {
            didSet {
                indexLabel.text = "\(index)";
            }
        }
        
        private let indexLabel: UILabel = UILabel(weight: .medium, textAlignment: .right, textColor: UIColor.h8e8e93)
        private let textLabel: UILabel = UILabel(weight: .medium, textAlignment: .left)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            contentView.layer.borderColor = UIColor.f2f2f7.cgColor
            contentView.layer.borderWidth = 1
            contentView.layer.cornerRadius = 8
            contentView.layer.masksToBounds = true
            
            let row = UIStackView(axis: .horizontal, alignment: .center, distribution: .fillEqually) {
                indexLabel
                textLabel
            }
            
            contentView.addSubview(row)
            row.autoPinEdgesToSuperviewEdges()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class KeysView: BEView, UICollectionViewDataSource {
        var keys: [String] = [] {
            didSet {
                collectionView.reloadData()
            }
        }
        private let collectionView: UICollectionView = {
            let layout = ColumnFlowLayout(
                cellsPerRow: 3,
                cellHeight: 37,
                minimumInteritemSpacing: 8,
                minimumLineSpacing: 8)
            let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
            return view
        }()
        
        override func commonInit() {
            super.commonInit()
            
            collectionView.register(Cell.self, forCellWithReuseIdentifier: "cell")
            collectionView.dataSource = self
            addSubview(collectionView)
            collectionView.autoPinEdgesToSuperviewEdges()
        }
        
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            1
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            keys.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! Cell
            cell.index = indexPath.row
            cell.key = keys[indexPath.row]
            return cell
        }
    }
}

extension Reactive where Base: CreateSecurityKeys.KeysView {
    var keys: Binder<[String]> {
        Binder(base) { view, keys in
            view.keys = keys
        }
    }
}