import Combine
import Foundation

/*
 Don't make this class as ObservableObject because view stops updating itself if this protocol is inherited for some reason ONLY on iOS 14
 */

@MainActor
open class BaseViewModel {
    // MARK: - Properties

    var subscriptions = [AnyCancellable]()

    // MARK: - Deinitializer

    deinit {
        debugPrint("\(String(describing: self)) deinited")
    }
}
