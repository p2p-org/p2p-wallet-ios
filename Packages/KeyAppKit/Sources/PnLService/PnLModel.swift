import Foundation

public protocol PnLModel {
    var total: Double { get }
    var pnlByMint: [String: Double] { get }
}
