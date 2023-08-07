import Combine
import Foundation

public protocol DeviceShareManager {
    func save(deviceShare: String)
    var deviceShare: String? { get }
    var deviceSharePublisher: AnyPublisher<String?, Never> { get }
}
