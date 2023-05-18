import Foundation

public class MockKeyAppHistoryProvider: KeyAppHistoryProvider {
    public init() {}

    public func transactions(secretKey: Data, pubKey: String, mint: String?, offset: Int, limit: Int) async throws -> [HistoryTransaction] {
        []
//        [sendTx, receiveTx, swapTx, stakeTx, unstakeTx, createAccountTx, closeAccountTx, burnTx, mintTx, unknownTx]
    }

//    private let sendTx = HistoryTransaction(
//        signature: "4WhwUsyNci7DmV9QA3hTQZsysX4f9YvaVo6HUWR2QejomcSaZbhacSfvB9we4dthhx8dwfLrWgR9tNtvjKHSYV6F",
//        date: Date(),
//        status: .success,
//        fees: [.init(type: "transaction", amount: "0.005", payer: "Fy7WgQxZLu4eL6ejpFbwARUiTTRH13Ag1akzaoESozuA", tokenPrice: "1")],
//        type: .send,
//        info: .init(
//            counterparty: .init(
//                address: "1NiyL95HU2yo8UqdrxvooppQSwqV8aqTT3tHyXdv6u4",
//                username: "ody344"
//            ),
//            tokens: [
//                .init(
//                    balance: .init(before: "3408.03638817", after: "3407.89046774"),
//                    info: .init(swapRole: nil, mint: "HZRCwxP2Vq9PCpPXooayhJ2bxTpo5xfpQrwB1svh332p", symbol: "test_symbol", tokenPrice: "1")
//                ),
//                .init(
//                    balance: .init(before: "0.0018444", after: "0.0018444"),
//                    info: .init(swapRole: nil, mint: "So11111111111111111111111111111111111111112", symbol: "SOL", tokenPrice: "1")
//                )
//            ]
//        )
//    )
//
//    private let receiveTx = HistoryTransaction(
//        signature: "3cRnZPCnGwBc5Y9KPW2brni2SCnbo7QhmYwSCEKyEMBMagVjxiGo1LXJSQb55rfQzvHRMACnTbAiZQvosg6f42d7",
//        date: Date(),
//        status: .success,
//        fees: [.init(type: "transaction", amount: "0.005", payer: "3f1jB3pieiLw1XstjrAG5pRC1xGaF3XTpjmhNMMmyGJA", tokenPrice: "1")],
//        type: .receive,
//        info: .init(
//            counterparty: .init(
//                address: "7VtcteYKpUY3ZW8bbPcGnnGGrBs8Ecmw27SxuqA5ipX3",
//                username: nil
//            ),
//            tokens: [
//                .init(
//                    balance: .init(before: "0", after: "0.009895302"),
//                    info: .init(swapRole: nil, mint: "So11111111111111111111111111111111111111112", symbol: "SOL", tokenPrice: "1")
//                )
//            ]
//        )
//    )
//
//    private let swapTx = HistoryTransaction(
//        signature: "3f2NjDiyqPLXudcmacW44cmnvCg4pakSLjK5xe2cieSpHaU5G1fQ3MwUGtw5z59LJaKYjPVmkeDR8Pt8kdJTYiay",
//        date: Date(),
//        status: .success,
//        fees: [.init(type: "transaction", amount: "0.005", payer: "3f1jB3pieiLw1XstjrAG5pRC1xGaF3XTpjmhNMMmyGJA", tokenPrice: "1")],
//        type: .swap,
//        info: .init(
//            counterparty: .init(
//                address: "7VtcteYKpUY3ZW8bbPcGnnGGrBs8Ecmw27SxuqA5ipX3",
//                username: nil
//            ),
//            tokens: [
//                .init(
//                    balance: .init(before: "0.01", after: "0.023159"),
//                    info: .init(swapRole: "to", mint: "AGFEad2et2ZJif9jaGpdMixQqvW5i81aBdvKe7PHNfz3", symbol: "s0", tokenPrice: "1")
//                ),
//                .init(
//                    balance: .init(before: "1.031182", after: "1.021182"),
//                    info: .init(swapRole: "from", mint: "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB", symbol: "s2", tokenPrice: "1")
//                ),
//                .init(
//                    balance: .init(before: "37425.240777191", after: "37425.240777191"),
//                    info: .init(swapRole: "transitive", mint: "So11111111111111111111111111111111111111112", symbol: "s1", tokenPrice: "1")
//                ),
//                .init(
//                    balance: .init(before: "64.172642", after: "64.172642"),
//                    info: .init(swapRole: "transitive", mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", symbol: "s3", tokenPrice: "1")
//                )
//            ],
//            swapPrograms: [.init(
//                address: "JUP4Fb2cqiRUcaTHdrPC8h2gNsA2ETXiPDD33WcGuJB",
//                name: nil
//            )]
//        )
//    )
//
//    private let stakeTx = HistoryTransaction(
//        signature: "evMmjayyY4MKWEdCbU152c3iqKBwmG6gZSNoFesQqLmX7UCZxBjKTX5n3xoHnyi1Z82FfJXvXeJDkjNgqnbUb6c",
//        date: Date(),
//        status: .success,
//        fees: [.init(type: "transaction", amount: "0.005", payer: "GccETn3yYfwVmgmfvcggsEAUKd5zqFTiKF5skj2bGYU7", tokenPrice: "1")],
//        type: .stake,
//        info: .init(
//            counterparty: nil,
//            tokens: [
//                .init(
//                    balance: .init(before: "0.046334466", after: "0.026324466"),
//                    info: .init(swapRole: nil, mint: "So11111111111111111111111111111111111111112", symbol: nil, tokenPrice: "1")
//                )
//            ],
//            voteAccount: .init(name: nil, address: "FKsC411dik9ktS6xPADxs4Fk2SCENvAiuccQHLAPndvk")
//        )
//    )
//
//    private let unstakeTx = HistoryTransaction(
//        signature: "29NY9Yxw911JwY9q4dC5DPgQpMoH5XFX5taGDHGRLmFZqN8UPRbJj719uKpwd6BcVepKZh6GVMdMahY3ogK9s3eK",
//        date: Date(),
//        status: .success,
//        fees: [.init(type: "transaction", amount: "0.000005", payer: "GccETn3yYfwVmgmfvcggsEAUKd5zqFTiKF5skj2bGYU7", tokenPrice: "1")],
//        type: .unstake,
//        info: .init(
//            counterparty: nil,
//            tokens: [
//                .init(
//                    balance: .init(before: "0.041071292", after: "0.046334466"),
//                    info: .init(swapRole: nil, mint: "So11111111111111111111111111111111111111112", symbol: nil, tokenPrice: "1")
//                )
//            ],
//            voteAccount: .init(name: nil, address: "FKsC411dik9ktS6xPADxs4Fk2SCENvAiuccQHLAPndvk")
//        )
//    )
//
//    private let createAccountTx = HistoryTransaction(
//        signature: "4dNta5EG7ajGtLGQtdDRARircc4e1HCibcF95GrHM3Wi5eah1eqt1Xco99KY7i8sR3j8tDrgp4ZVV7DzTTGGLB4m",
//        date: Date(),
//        status: .success,
//        fees: [.init(type: "transaction", amount: "0.000005", payer: "GccETn3yYfwVmgmfvcggsEAUKd5zqFTiKF5skj2bGYU7", tokenPrice: "1")],
//        type: .createAccount,
//        info: .init(
//            counterparty: .init(
//                address: "FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT",
//                username: nil
//            ),
//            tokens: [
//                .init(
//                    balance: .init(before: "0", after: "1"),
//                    info: .init(swapRole: nil, mint: "9vMJfxuKxXBoEa7rM12mYLMwTacLMLDJqHozw96WQL8i", symbol: "test1", tokenPrice: "1")
//                ),
//                .init(
//                    balance: .init(before: "0.017628283", after: "0.017628283"),
//                    info: .init(swapRole: nil, mint: "So11111111111111111111111111111111111111112", symbol: "test2", tokenPrice: "1")
//                )
//            ]
//        )
//    )
//
//    private let closeAccountTx = HistoryTransaction(
//        signature: "3fPGdk93gM1mp7jj8B8vqE8K3Y6cEi4uRNuenKYcVrUDnu1ZSNvxvHEPtWAJqRkH8bSqJRmLLrRwUyk3zRhChSEh",
//        date: Date(),
//        status: .success,
//        fees: [.init(type: "transaction", amount: "0.000005", payer: "3f1jB3pieiLw1XstjrAG5pRC1xGaF3XTpjmhNMMmyGJA", tokenPrice: "1")],
//        type: .closeAccount,
//        info: .init(
//            counterparty: .init(
//                address: "Xa1LXpaM5Yu393JwS9XMN5hktnKeUVWfGfbbn7i6SWXj",
//                username: "Test.key"
//            ),
//            tokens: [
//                .init(
//                    balance: .init(before: "0.408761028", after: "0.410795308"),
//                    info: .init(swapRole: nil, mint: "So11111111111111111111111111111111111111112", symbol: nil, tokenPrice: "1")
//                )
//            ]
//        )
//    )
//
//    private let burnTx = HistoryTransaction(
//        signature: "3gVo7ePp1CRktcfFca9SyePXLvGZzMDjeV63BkPVnRAxKVeRKZN6xPJgfK4Ny2c4yRKDyxU9hD8gXuPWABVVb9iA",
//        date: Date(),
//        status: .success,
//        fees: [.init(type: "transaction", amount: "0.000015", payer: "3f1jB3pieiLw1XstjrAG5pRC1xGaF3XTpjmhNMMmyGJA", tokenPrice: "1")],
//        type: .burn,
//        info: .init(
//            counterparty: nil,
//            tokens: [
//                .init(
//                    balance: .init(before: "2.456842", after: "2.417167"),
//                    info: .init(swapRole: nil, mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", symbol: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", tokenPrice: "1")
//                )
//            ]
//        )
//    )
//
//    private let mintTx = HistoryTransaction(
//        signature: "yp21cB7sFRhQepIVOSnApb4gPbDS9aV6PzGhlqR0eaxVJhbae0eLw3tlm5dTzAm4oCPFnRXvvNHkH9eMw6C1qbme",
//        date: Date(),
//        status: .success,
//        fees: [.init(type: "transaction", amount: "0.000015", payer: "3f1jB3pieiLw1XstjrAG5pRC1xGaF3XTpjmhNMMmyGJA", tokenPrice: "1")],
//        type: .mint,
//        info: .init(
//            counterparty: nil,
//            tokens: [
//                .init(
//                    balance: .init(before: "2.456842", after: "2.417167"),
//                    info: .init(swapRole: nil, mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", symbol: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", tokenPrice: "1")
//                )
//            ]
//        )
//    )
//
//    private let unknownTx = HistoryTransaction(
//        signature: "bjihAEokfgNmCd1dIWiDna5OTX6UiTVrI65NbFhciI28BVjfvSWGzwE5BEsxuKPqgovh6x5BQGi5iYyS2T99rn4l",
//        date: Date(),
//        status: .success,
//        fees: [.init(type: "transaction", amount: "0.000015", payer: "3f1jB3pieiLw1XstjrAG5pRC1xGaF3XTpjmhNMMmyGJA", tokenPrice: "1")],
//        type: .unknown,
//        info: .init(
//            counterparty: nil,
//            tokens: [
//                .init(
//                    balance: .init(before: "2.456842", after: "2.417167"),
//                    info: .init(swapRole: nil, mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", symbol: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", tokenPrice: "1")
//                )
//            ]
//        )
//    )
}
