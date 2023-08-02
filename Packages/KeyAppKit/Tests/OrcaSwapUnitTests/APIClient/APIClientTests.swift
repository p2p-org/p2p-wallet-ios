import XCTest
import OrcaSwapSwift

class APIClientTests: XCTestCase {
    private let client = APIClient(configsProvider: MockConfigsProvider())

    func testRetrievingTokens() async throws {
        let tokens = try await client.getTokens()
        XCTAssertEqual(tokens.count, 294)
    }
    
//    func testRetrievingAquafarms() async throws {
//        let aquafarms = try await client.getAquafarms()
//        XCTAssertEqual(aquafarms.count, 127)
//    }
    
    func testRetrievingPools() async throws {
        let pools = try await client.getPools()
        XCTAssertEqual(pools.count, 153)
    }
    
    func testRetrievingProgramId() async throws {
        let programId = try await client.getProgramID()
        XCTAssertEqual(.tokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA, programId.token)
    }
}
