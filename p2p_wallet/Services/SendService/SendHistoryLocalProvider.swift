//
//  SendHistoryLocalProvider.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 28.11.2022.
//

import Cache
import Foundation
import Send

class SendHistoryLocalProvider: SendHistoryProvider {
    func getCacheDirectoryPath() -> URL {
        let arrayPaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectoryPath = arrayPaths[0]
        return cacheDirectoryPath
    }

    func getRecipients(
        _: Int
    ) async throws -> [Recipient] { fatalError("getRecipients(_:) has not been implemented") }

    func save(_: [Recipient]) async throws {}
}
