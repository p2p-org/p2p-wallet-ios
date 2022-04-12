//
// Created by Giang Long Tran on 12.04.2022.
//

import BECollectionView
import BEPureLayout
import Foundation
import UIKit

extension History {
    class Scene: BEScene {
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }

        override func build() -> UIView {
            BEVStack {
                NewWLNavigationBar(initialTitle: L10n.history)
                    .backIsHidden(true)

                BEDynamicSectionsCollectionView(
                    viewModel: SceneModel(),
                    mapDataToSections: { viewModel in
                        let transactions = viewModel.getData(type: SolanaSDK.ParsedTransaction.self)

                        let calendar = Calendar.current
                        let today = calendar.startOfDay(for: Date())
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .medium
                        dateFormatter.timeStyle = .none
                        dateFormatter.locale = Locale.shared

                        let dictionary = Dictionary(grouping: transactions) { item -> Int in
                            guard let date = item.blockTime else { return .max }
                            let createdDate = calendar.startOfDay(for: date)
                            return calendar.dateComponents([.day], from: createdDate, to: today).day ?? 0
                        }

                        return dictionary.keys.sorted()
                            .map { key -> BEDynamicSectionsCollectionView.SectionInfo in
                                var sectionInfo: String
                                switch key {
                                case 0:
                                    sectionInfo = L10n.today + ", " + dateFormatter.string(from: today)
                                case 1:
                                    sectionInfo = L10n.yesterday
                                    if let date = calendar.date(byAdding: .day, value: -1, to: today) {
                                        sectionInfo += ", " + dateFormatter.string(from: date)
                                    }
                                case .max:
                                    sectionInfo = L10n.unknownDate
                                default:
                                    if let date = calendar.date(byAdding: .day, value: -key, to: today) {
                                        sectionInfo = dateFormatter.string(from: date)
                                    } else {
                                        sectionInfo = L10n.unknownDate
                                    }
                                }
                                return .init(
                                    userInfo: sectionInfo,
                                    items: dictionary[key] ?? []
                                )
                            }
                    },
                    layout: .init(
                        header: .init(
                            viewClass: SectionHeaderView.self,
                            heightDimension: .estimated(15)
                        ),
                        cellType: TransactionCell.self,
                        emptyCellType: WLEmptyCell.self,
                        interGroupSpacing: 1,
                        itemHeight: .estimated(85)
                    )
                )
            }
        }
    }
}
