import KeyAppNetworking
import XCTest
@testable import PnLService

final class PnLServiceTests: XCTestCase {
    func testEncodingRequest() async throws {
        let request = PnLRPCRequest(
            userWallet: "EXRV9Hu3VswiEDYVcx9tLfF7EX3z3zEH19g363KQe3Kd",
            mints: [
                "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
                "CKfatsPMUf8SkiURsDXs7eK6GWb4Jsd6UDbs7twMCWxo",
            ]
        )

        let encoded = try String(data: JSONEncoder().encode(request), encoding: .utf8)!
        XCTAssertEqual(
            encoded,
            #"{"user_wallet":"EXRV9Hu3VswiEDYVcx9tLfF7EX3z3zEH19g363KQe3Kd","mints":["EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","CKfatsPMUf8SkiURsDXs7eK6GWb4Jsd6UDbs7twMCWxo"]}"#
        )
    }

    func testRequest_SuccessfulResponse_ReturnsData() async throws {
        let mockURLSession =
            MockURLSession(
                responseString: #"{"jsonrpc":"2.0","id":"12","result":{"total":{"usd_amount":"+1.23","percent":"-3.45"},"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v":{"usd_amount":"+1.23","percent":"-3.45"},"CKfatsPMUf8SkiURsDXs7eK6GWb4Jsd6UDbs7twMCWxo":{"usd_amount":"+1.23","percent":"-3.45"}}}"#
            )

        let service = PnLServiceImpl(urlSession: mockURLSession)
        let result = try await service.getPNL(userWallet: "", mints: [])

        XCTAssertEqual(result.total?.usdAmount, "+1.23")
        XCTAssertEqual(result.total?.percent, "-3.45")
        XCTAssertEqual(result.pnlByMint["EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"]?.usdAmount, "+1.23")
        XCTAssertEqual(result.pnlByMint["EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"]?.percent, "-3.45")
        XCTAssertEqual(result.pnlByMint["CKfatsPMUf8SkiURsDXs7eK6GWb4Jsd6UDbs7twMCWxo"]?.usdAmount, "+1.23")
        XCTAssertEqual(result.pnlByMint["CKfatsPMUf8SkiURsDXs7eK6GWb4Jsd6UDbs7twMCWxo"]?.percent, "-3.45")
    }
}
