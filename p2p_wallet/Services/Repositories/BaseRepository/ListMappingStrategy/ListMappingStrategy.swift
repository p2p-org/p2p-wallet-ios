import Foundation

protocol MappingStrategy {
    associatedtype ItemType: ListItem
    func map(oldData: ItemType?, newData: ItemType?) -> ItemType?
}

struct AppendUniqueItemListMappingStrategy<ItemType: ListItem>: MappingStrategy where ItemType: Collection, ItemType.Element: ListItem {
    func map(oldData: ItemType?, newData: ItemType?) -> ItemType? {
        guard var data = oldData else { return newData }
        // append data that is currently not existed in current data array
        if let newData {
            data += newData.filter { newRecord in
                !data.contains { $0.id == newRecord.id }
            }
        }
        return data
    }
}

//func map(oldData: [ListItemType]?, newData: [ListItemType]?) -> [ListItemType]? {
//    guard var data = oldData else { return newData }
//
//    // for pagination
//    if let paginationStrategy = paginationStrategy {
//        // append data that is currently not existed in current data array
//        if let newData {
//            data += newData.filter {!data.contains($0)}
//        }
//
//        // resign state
//        paginationStrategy.moveToNextPage()
//        paginationStrategy.checkIfLastPageLoaded(lastSnapshot: newData)
//    }
//
//    // without pagination
//    else {
//        // replace the current data
//        if let newData {
//            data = newData
//        }
//    }
//
//    return data
//}
