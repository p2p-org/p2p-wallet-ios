import Foundation
import OrcaSwapSwift

class MockConfigsProvider: OrcaSwapConfigsProvider {
    func getData(reload: Bool) async throws -> Data {
        let thisSourceFile = URL(fileURLWithPath: #file)
        let thisDirectory = thisSourceFile.deletingLastPathComponent()
        let resourceURL = thisDirectory.appendingPathComponent("../../Resources/orcaconfigs-mainnet.json")
        let data = try! Data(contentsOf: resourceURL)
        return data
    }
}
