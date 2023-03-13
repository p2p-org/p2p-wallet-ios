//
//  File.swift
//
//
//  Created by Giang Long Tran on 12.03.2023.
//

import Foundation

enum Helper {
    static func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds) * 1000000000)
    }
}
