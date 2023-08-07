import Foundation

public protocol OrcaSwapAPIClient {
    var configsProvider: OrcaSwapConfigsProvider { get }
    func reload() async throws
    func getTokens() async throws -> [String: TokenValue]
    func getPools() async throws -> [String: Pool]
}

public extension OrcaSwapAPIClient {
    // MARK: - Methods

    func reload() async throws {
        _ = try await configsProvider.getData(reload: true)
    }

    func getTokens() async throws -> [String: TokenValue] {
        let data = try await configsProvider.getConfigs()
        let response = try JSONDecoder().decode(OrcaInfoResponse.self, from: data)
        return response.value.tokens
    }

    func getPools() async throws -> [String: Pool] {
        let data = try await configsProvider.getConfigs()
        let response = try JSONDecoder().decode(OrcaInfoResponse.self, from: data)
        return response.value.pools
    }

    func getProgramID() async throws -> ProgramIDS {
        let data = try await configsProvider.getConfigs()
        let response = try JSONDecoder().decode(OrcaInfoResponse.self, from: data)
        return response.value.programIds
    }
}

public class APIClient: OrcaSwapAPIClient {
    // MARK: - Properties

    public let configsProvider: OrcaSwapConfigsProvider

    // MARK: - Initializers

    public init(configsProvider: OrcaSwapConfigsProvider) {
        self.configsProvider = configsProvider
    }
}
