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

    func save(_ recipients: [Recipient]?) async throws {
        let cacheFile = getCacheFile()

        if let recipients = recipients {
            let data = try JSONEncoder().encode(recipients)
            try data.write(to: cacheFile)
        } else {
            try? FileManager.default.removeItem(at: cacheFile)
        }
    }

    func getRecipients() async throws -> [Recipient]? {
        let cacheFile = getCacheFile()
        guard let data = try? Data(contentsOf: cacheFile) else { return nil }

        return (try? JSONDecoder().decode([Recipient].self, from: data)) ?? []
    }
}
