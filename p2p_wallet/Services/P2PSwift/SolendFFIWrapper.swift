// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeyappSdk
import P2PSwift
import SolanaSwift

internal struct SolendResponse<Success: Codable>: Codable {
    let success: Success?
    let error: String?
}

public class SolendFFIWrapper: Solend {
    private static let concurrentQueue = DispatchQueue(label: "SolendSDK", attributes: .concurrent)
    private var runtime: UnsafeMutablePointer<Runtime>?

    public init() {
        runtime = spawn_runtime(3, 3)
    }
    
    deinit {
        drop_runtime(runtime)
    }

    public func getConfig(environment: SolendEnvironment) async throws -> SolendConfig {
        // Fetch
        let jsonResult: String = try await execute { get_solend_config(&self.runtime, environment.rawValue) }
        print(jsonResult)

        // Decode
        struct Success: Codable {
            let config: SolendConfig
        }

        // Return
        let response = try JSONDecoder().decode(
            SolendResponse<Success>.self,
            from: jsonResult.data(using: .utf8)!
        )

        if let error = response.error { throw SolendError.message(error) }
        if let success = response.success { return success.config }
        throw SolendError.noResult
    }

    public func getCollateralAccounts(rpcURL: String, owner: String) async throws -> [SolendCollateralAccount] {
        // Fetch
        let jsonResult: String = try await execute { get_solend_collateral_accounts(&self.runtime, rpcURL, owner) }

        // Decode
        struct Success: Codable {
            let accounts: [SolendCollateralAccount]
        }

        // Return
        let response = try JSONDecoder().decode(
            SolendResponse<Success>.self,
            from: jsonResult.data(using: .utf8)!
        )

        if let error = response.error { throw SolendError.message(error) }
        if let success = response.success { return success.accounts }
        throw SolendError.noResult
    }

    public func getMarketInfo(
        symbols: [SolendSymbol],
        pool: String
    ) async throws -> [(token: SolendSymbol, marketInfo: SolendMarketInfo)] {
        let jsonResult: String = try await execute {
            get_solend_market_info(&self.runtime, symbols.joined(separator: ","), pool)
        }

        // Decode
        enum MarketInfoElement: Codable {
            case marketInfoClass(SolendMarketInfo)
            case token(String)

            var asToken: String {
                get throws {
                    guard case let .token(value) = self else { throw SolendError.decodingException }
                    return value
                }
            }

            var asMarketInfo: SolendMarketInfo {
                get throws {
                    guard case let .marketInfoClass(value) = self else { throw SolendError.decodingException }
                    return value
                }
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let x = try? container.decode(String.self) {
                    self = .token(x)
                    return
                }
                if let x = try? container.decode(SolendMarketInfo.self) {
                    self = .marketInfoClass(x)
                    return
                }
                throw DecodingError.typeMismatch(
                    MarketInfoElement.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Wrong type for MarketInfoElement"
                    )
                )
            }

            func encode(to _: Encoder) throws { fatalError("MarketInfoElement doesn't support encode") }
        }

        struct Success: Codable {
            let marketInfo: [[MarketInfoElement]]

            private enum CodingKeys: String, CodingKey {
                case marketInfo = "market_info"
            }
        }

        // Return
        let response = try JSONDecoder().decode(
            SolendResponse<Success>.self,
            from: jsonResult.data(using: .utf8)!
        )

        if let error = response.error { throw SolendError.message(error) }
        if let success = response.success {
            return try success.marketInfo.map { (try $0.first!.asToken, try $0.last!.asMarketInfo) }
        }
        throw SolendError.noResult
    }

    public func getUserDeposits(owner: String, poolAddress: String) async throws -> [SolendUserDeposit] {
        let jsonResult: String = try await execute {
            get_solend_user_deposits(&self.runtime, owner, poolAddress)
        }

        struct Success: Codable {
            let marketInfo: [SolendUserDeposit]

            private enum CodingKeys: String, CodingKey {
                case marketInfo = "market_info"
            }
        }

        let response = try JSONDecoder().decode(
            SolendResponse<Success>.self,
            from: jsonResult.data(using: .utf8)!
        )

        if let error = response.error { throw SolendError.message(error) }
        if let success = response.success { return success.marketInfo }
        throw SolendError.noResult
    }

    public func getUserDepositBySymbol(
        owner: String,
        symbol: SolendSymbol,
        poolAddress: String
    ) async throws -> SolendUserDeposit {
        let jsonResult: String = try await execute {
            get_solend_user_deposit_by_symbol(&self.runtime, owner, symbol, poolAddress)
        }

        struct Success: Codable {
            let marketInfo: SolendUserDeposit

            private enum CodingKeys: String, CodingKey {
                case marketInfo = "market_info"
            }
        }

        let response = try JSONDecoder().decode(
            SolendResponse<Success>.self,
            from: jsonResult.data(using: .utf8)!
        )

        if let error = response.error { throw SolendError.message(error) }
        if let success = response.success { return success.marketInfo }
        throw SolendError.noResult
    }

    public func getDepositFee(
        rpcUrl: String,
        owner: String,
        tokenAmount: UInt64,
        tokenSymbol: SolendSymbol
    ) async throws -> SolendDepositFee {
        let jsonResult: String = try await execute {
            get_solend_deposit_fees(&self.runtime, rpcUrl, owner, tokenAmount, tokenSymbol)
        }

        let response = try JSONDecoder().decode(
            SolendResponse<SolendDepositFee>.self,
            from: jsonResult.data(using: .utf8)!
        )

        if let error = response.error { throw SolendError.message(error) }
        if let success = response.success { return success }
        throw SolendError.noResult
    }

    public func createDepositTransaction(
        solanaRpcUrl: String,
        relayProgramId: String,
        amount: UInt64,
        symbol: SolendSymbol,
        ownerAddress: String,
        environment: SolendEnvironment,
        lendingMarketAddress: String,
        blockHash: String,
        freeTransactionsCount: UInt32,
        needToUseRelay: Bool,
        payInFeeToken: SolendPayFeeInToken?,
        feePayerAddress: String
    ) async throws -> [SolanaSerializedTransaction] {
        var payInFeeTokenJson = ""
        if let payInFeeToken = payInFeeToken {
            payInFeeTokenJson = String(data: try JSONEncoder().encode(payInFeeToken), encoding: .utf8)!
        }

        let jsonResult: String = try await execute {
            create_solend_deposit_transactions(
                &self.runtime,
                solanaRpcUrl,
                relayProgramId,
                amount,
                symbol,
                ownerAddress,
                environment.rawValue,
                lendingMarketAddress,
                blockHash,
                freeTransactionsCount,
                needToUseRelay,
                payInFeeTokenJson,
                feePayerAddress
            )
        }

        struct Success: Codable {
            let transactions: [String]
        }

        let response = try JSONDecoder().decode(
            SolendResponse<Success>.self,
            from: jsonResult.data(using: .utf8)!
        )

        if let error = response.error { throw SolendError.message(error) }
        if let success = response.success { return success.transactions }
        throw SolendError.noResult
    }

    public func createWithdrawTransaction(
        solanaRpcUrl: String,
        relayProgramId: String,
        amount: UInt64,
        symbol: SolendSymbol,
        ownerAddress: String,
        environment: SolendEnvironment,
        lendingMarketAddress: String,
        blockHash: String,
        freeTransactionsCount: UInt32,
        needToUseRelay: Bool,
        payInFeeToken: SolendPayFeeInToken?,
        feePayerAddress: String
    ) async throws -> [SolanaSerializedTransaction] {
        var payInFeeTokenJson = ""
        if let payInFeeToken = payInFeeToken {
            payInFeeTokenJson = String(data: try JSONEncoder().encode(payInFeeToken), encoding: .utf8)!
        }

        let jsonResult: String = try await execute {
            create_solend_withdraw_transactions(
                &self.runtime,
                solanaRpcUrl,
                relayProgramId,
                amount,
                symbol,
                ownerAddress,
                environment.rawValue,
                lendingMarketAddress,
                blockHash,
                freeTransactionsCount,
                needToUseRelay,
                payInFeeTokenJson,
                feePayerAddress
            )
        }

        struct Success: Codable {
            let transactions: [String]
        }

        let response = try JSONDecoder().decode(
            SolendResponse<Success>.self,
            from: jsonResult.data(using: .utf8)!
        )

        if let error = response.error { throw SolendError.message(error) }
        if let success = response.success { return success.transactions }
        throw SolendError.noResult
    }

    // Utils
    internal func execute(_ networkCall: @escaping () -> UnsafeMutablePointer<CChar>?) async throws -> String {
        await withCheckedContinuation { continuation in
            SolendFFIWrapper.concurrentQueue.async {
                let result = networkCall()
                continuation.resume(returning: String(cString: result!))
            }
        }
    }
}
