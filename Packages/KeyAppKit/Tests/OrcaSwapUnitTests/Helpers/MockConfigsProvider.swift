import Foundation
import OrcaSwapSwift

class MockConfigsProvider: OrcaSwapConfigsProvider {
    func getData(reload: Bool) async throws -> Data {
        let thisSourceFile = URL(fileURLWithPath: #file)
        let resourceURL = thisSourceFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("orcaconfigs-mainnet.json")
        print(resourceURL)
        let data = try! Data(contentsOf: resourceURL)
        return data
    }
}
