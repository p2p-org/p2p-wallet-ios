import Combine
import Foundation

class FeeRelayConfig: ObservableObject {
    static let shared = FeeRelayConfig()

    @Published var disableFeeTransaction: Bool = false
}
