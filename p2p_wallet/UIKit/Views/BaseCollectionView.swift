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

    @available(*, unavailable,
               message: "Loading this view from a nib is unsupported in favor of initializer dependency injection.")
    required init?(coder _: NSCoder) {
        fatalError("Loading this view from a nib is unsupported in favor of initializer dependency injection.")
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
