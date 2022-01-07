//
// Created by Giang Long Tran on 06.01.22.
//

import Foundation
import BECollectionView

struct CollectionViewMappingStrategy {
    static func byData<T: Hashable>(viewModel: BEListViewModelType, forType: T.Type, where datePath: KeyPath<T, Date>) -> [BEDynamicSectionsCollectionView.SectionInfo] {
        let transactions = viewModel.getData(type: forType)
        
        let dictionary = Dictionary(grouping: transactions) { item -> Date in
            let date = item[keyPath: datePath] ?? Date()
            return Calendar.current.startOfDay(for: date)
        }
        
        return dateFormatter(dictionary: dictionary)
    }
    
    static func byData<T: Hashable>(viewModel: BEListViewModelType, forType: T.Type, where datePath: KeyPath<T, Date?>) -> [BEDynamicSectionsCollectionView.SectionInfo] {
        let transactions = viewModel.getData(type: forType)
        
        let dictionary = Dictionary(grouping: transactions) { item -> Date in
            let date = item[keyPath: datePath] ?? Date()
            return Calendar.current.startOfDay(for: date)
        }
        
        return dateFormatter(dictionary: dictionary)
    }
    
    private static func dateFormatter<T: Hashable>(dictionary: Dictionary<Date, [T]>) -> [BEDynamicSectionsCollectionView.SectionInfo] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.shared
        
        return dictionary.keys.sorted()
            .map { key in
                BEDynamicSectionsCollectionView.SectionInfo(
                    userInfo: dateFormatter.string(from: key),
                    items: dictionary[key] ?? []
                )
            }
    }
}
