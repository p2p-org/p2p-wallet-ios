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
    func getCacheFile() -> URL {
        let arrayPaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectoryPath = arrayPaths[0]
        return cacheDirectoryPath.appendingPathComponent("/send-history.data")
    }

    func getRecipients(_: Int) async throws -> [Recipient] {
        let cacheFile = getCacheFile()
        guard let data = try? Data(contentsOf: cacheFile) else { return [] }
        
        return (try? JSONDecoder().decode([Recipient].self, from: data)) ?? []
    }

    func save(_ recipients: [Recipient]) async throws {
        let cacheFile = getCacheFile()
        let data = try JSONEncoder().encode(recipients)
        
        try data.write(to: cacheFile)
    }
}
