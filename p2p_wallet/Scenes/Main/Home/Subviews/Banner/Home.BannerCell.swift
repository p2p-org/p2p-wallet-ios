//
// Created by Giang Long Tran on 18.02.2022.
//

import BECollectionView
import BEPureLayout
import Foundation
import RxSwift

extension Home {
    class BannerCell: BECollectionCell {

        fileprivate var header = BERef<UIView>()
        fileprivate var title = BERef<UILabel>()
        fileprivate var action = BERef<UILabel>()
        fileprivate var icon = BERef<UIImageView>()

        override func build() -> UIView {
            BEZStack {
                BEZStackPosition(mode: .fill) {
                    BEVStack {
                        UILabel(text: "<title>", textSize: 15, weight: .semibold, numberOfLines: 3)
                            .bind(title)
                            .padding(.init(top: 0, left: 20, bottom: 0, right: 120))
                            .bind(header)

                        UILabel(text: "<action>", textSize: 13, weight: .semibold)
                            .bind(action)
                            .padding(.init(x: 20, y: 0))
                            .frame(height: 42)
                            .backgroundColor(color: .background)
                    }.frame(width: 300, height: 145)
                        .box(cornerRadius: 16)
                }.mediumShadow()

                BEZStackPosition(mode: .pinEdges(top: false, left: false, bottom: true, right: true)) {
                    UIImageView()
                        .bind(icon)
                        .padding(.init(top: 0, left: 0, bottom: 50, right: 0))
                }
            }
        }
    }
}

extension Home.BannerCell: BECollectionViewCell {
    func hideLoading() {}

    func showLoading() {}

    func setUp(with item: AnyHashable?) {
        print(item)
        guard let item = item as? Banners.Banner else { return }
        print(item.getInfo())
        title.view?.text = item.getInfo()[.title] as? String
        action.view?.text = item.getInfo()[.action] as? String
        icon.view?.image = item.getInfo()[.icon] as? UIImage
        header.view?.backgroundColor = item.getInfo()[.background] as? UIColor
    }
}
