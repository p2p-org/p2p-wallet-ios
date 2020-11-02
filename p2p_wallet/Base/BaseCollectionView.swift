//
//  BaseCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation

class BaseCollectionView: UICollectionView {
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .clear
    }
    
    func registerCells(_ cellTypes: [UICollectionViewCell.Type]) {
        for type in cellTypes {
            register(type, forCellWithReuseIdentifier: String(describing: type))
        }
    }
}
