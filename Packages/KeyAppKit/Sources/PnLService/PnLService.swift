import Foundation

public protocol PnLService {
    func getPNL() async throws -> String
}
