//
//  HistoryDebug.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.05.2023.
//

import Foundation
import History

class HistoryDebug: ObservableObject {
    static let shared = HistoryDebug()

    @Published var mockItems: [any RendableListTransactionItem] = []

    private init() {}

    func clear() {
        mockItems = []
    }

    func addWormholeSend() {
        let rawData = """
        {"signature":"47dfD8hhLYcaBugeuvEdQ1wZEcgMcgGcdWdSPAZXKNf2Vw5xW2U8hVn8VuMUXQTL88WLKU95S98qZQ7G2PeYNQBx","date":"2023-05-23T21:21:18Z","status":"success","fees":[{"type":"transaction","token":{"symbol":"SOL","name":"Wrapped SOL","mint":"So11111111111111111111111111111111111111112","logo_url":"https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png","usd_rate":"1","coingecko_id":"wrapped-sol","decimals":9},"amount":{"usd_amount":"0.000015","amount":"0.000015"},"payer":"FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT"}],"block_number":1,"type":"wormhole_send","info":{"to":{"address":"0101010101010101010101010101010101010101","name":null},"bridge_service_key":"Eu5rpz6WQSRps5qAwkowd4RutUHMpJDqRpeZv383ULop","token_amount":{"token":{"symbol":"WETH","name":"Token Wrapped Ether (Wormhole)","mint":"7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs","logo_url":"https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs/logo.png","usd_rate":"1","coingecko_id":null,"decimals":9},"amount":{"usd_amount":"0.01573143","amount":"0.01573143"}}},"error":null}
        """

        do {
            let data = Data(rawData.utf8)
            let historyTransaction = try JSONDecoder().decode(HistoryTransaction.self, from: data)
            let item = RendableListHistoryTransactionItem(trx: historyTransaction, allTokens: [])

            let match = mockItems.contains { $0.id == item.id }
            if match == false {
                mockItems.append(item)
            }
        } catch {
            print(error)
        }
    }

    func addWormholeReceive() {
        let rawData = """
        {"signature":"?XtP35tojjoNV4BeuAmrzcHvNLeNhRRvMG89fw8aGXxgoiV3sMY65r1cJCpF8AA2wCJwYDqngkcib94smtLKY6k1","date":"2023-05-23T21:21:18Z","status":"success","fees":[{"type":"transaction","token":{"symbol":"SOL","name":"Wrapped SOL","mint":"So11111111111111111111111111111111111111112","logo_url":"https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png","usd_rate":"1","coingecko_id":"wrapped-sol","decimals":9},"amount":{"usd_amount":"0.000005","amount":"0.000005"},"payer":"HZBb3y17RbkYk9wZfcoYMvGjyXcewichSyswgLVckVGg"}],"block_number":1,"type":"wormhole_receive","info":{"to":null,"bridge_service_key":"5C9gVbvHysxMwyDn4RPvCp1c7d7cp1Az5kPRuwWjJAXV","token_amount":{"token":{"symbol":"WETH","name":"Token Wrapped Ether (Wormhole)","mint":"7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs","logo_url":"https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs/logo.png","usd_rate":"1","coingecko_id":null,"decimals":9},"amount":{"usd_amount":"0.04869668","amount":"0.04869668"}}},"error":null}
        """

        do {
            let data = Data(rawData.utf8)
            let historyTransaction = try JSONDecoder().decode(HistoryTransaction.self, from: data)
            let item = RendableListHistoryTransactionItem(trx: historyTransaction, allTokens: [])

            let match = mockItems.contains { $0.id == item.id }
            if match == false {
                mockItems.append(item)
            }
        } catch {
            print(error)
        }
    }
}
