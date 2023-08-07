import Combine
import Foundation

protocol SolanaTracker {
    var unstableSolana: AnyPublisher<Void, Never> { get }

    func startTracking()
    func stopTracking()
}
