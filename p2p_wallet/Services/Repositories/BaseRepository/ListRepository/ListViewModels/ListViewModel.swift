import Foundation
import Combine

/// Reusable ViewModel to manage a List of some Kind of item
@MainActor
class ListViewModel<Repository: AnyListRepository>: ItemViewModel<Repository> {

    // MARK: - Actions

//    /// Update multiple records with a closure
//    /// - Parameter closure: updating closure
//    func batchUpdate(closure: ([ItemType]) -> [ItemType]) {
//        let newData = closure(data)
//        overrideData(by: newData)
//    }
//
//    /// Update item that matchs predicate
//    /// - Parameters:
//    ///   - predicate: predicate to find item
//    ///   - transform: transform item before udpate
//    /// - Returns: true if updated, false if not
//    @discardableResult
//    func updateItem(where predicate: (ItemType) -> Bool, transform: (ItemType) -> ItemType?) -> Bool {
//        // modify items
//        var itemsChanged = false
//        if let index = data.firstIndex(where: predicate),
//           let item = transform(data[index]),
//           item != data[index]
//        {
//            itemsChanged = true
//            var data = self.data
//            data[index] = item
//            overrideData(by: data)
//        }
//
//        return itemsChanged
//    }
//
//    /// Insert item into list or update if needed
//    /// - Parameters:
//    ///   - item: item to be inserted
//    ///   - predicate: predicate to find item
//    ///   - shouldUpdate: should update instead
//    /// - Returns: true if inserted, false if not
//    @discardableResult
//    func insert(_ item: ItemType, where predicate: ((ItemType) -> Bool)? = nil, shouldUpdate: Bool = false) -> Bool
//    {
//        var items = data
//
//        // update mode
//        if let predicate = predicate {
//            if let index = items.firstIndex(where: predicate), shouldUpdate {
//                items[index] = item
//                overrideData(by: items)
//                return true
//            }
//        }
//
//        // insert mode
//        else {
//            items.append(item)
//            overrideData(by: items)
//            return true
//        }
//
//        return false
//    }
//
//    /// Remove item that matches a predicate from list
//    /// - Parameter predicate: predicate to find item
//    /// - Returns: removed item
//    @discardableResult
//    func removeItem(where predicate: (ItemType) -> Bool) -> ItemType? {
//        var result: ItemType?
//        var data = self.data
//        if let index = data.firstIndex(where: predicate) {
//            result = data.remove(at: index)
//        }
//        if result != nil {
//            overrideData(by: data)
//        }
//        return nil
//    }
}
