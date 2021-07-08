//
//  HomeFriendCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Foundation
import RxSwift
import BECollectionView

struct Friend: Hashable {
    let name: String
}

class FriendsViewModel: BEListViewModel<Friend> {
    override func createRequest() -> Single<[Friend]> {
        Single<[Friend]>.just(data).delay(.seconds(Int.random(in: 2..<6)), scheduler: MainScheduler.instance)
            .map { _ in
                [
                    Friend(name: "Ty"),
                    Friend(name: "Phi"),
                    Friend(name: "Phid")
                ]
            }
    }
}

class HomeFriendCell: BaseCollectionViewCell, BECollectionViewCell {
    override var padding: UIEdgeInsets {.zero}
    let imageView = UIImageView(width: 56, height: 56, backgroundColor: .gray, cornerRadius: 28)
    let nameLabel = UILabel(text: "friend", textSize: 12, textAlignment: .center)
    
    override func commonInit() {
        super.commonInit()
        stackView.spacing = 8
        stackView.alignment = .center
        
        stackView.addArrangedSubviews {
            imageView
            nameLabel
        }
    }
    
    func setUp(with item: AnyHashable?) {
        guard let friend = item as? Friend else {return}
        nameLabel.text = friend.name
    }
}
