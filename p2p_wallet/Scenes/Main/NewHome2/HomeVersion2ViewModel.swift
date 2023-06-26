import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver

class HomeVersion2ViewModel: BaseViewModel, ObservableObject {
    enum Category {
        case cash
        case crypto
    }

    @Published var category: Category = .cash

    override init() {
        super.init()
    }
}
