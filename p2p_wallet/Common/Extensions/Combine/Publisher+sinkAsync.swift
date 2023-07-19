import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Self.Failure == Never {
    func sinkAsync(receiveValue: @escaping ((Self.Output) async throws -> Void)) -> AnyCancellable {
        sink { output in
            Task {
                try await receiveValue(output)
            }
        }
    }
}
