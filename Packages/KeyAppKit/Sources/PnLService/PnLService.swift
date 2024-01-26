import Foundation

public protocol PnLService {
    associatedtype PnL: PnLModel
    func getPNL() async throws -> PnL
}
