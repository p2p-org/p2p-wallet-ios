//
//  File.swift
//  
//
//  Created by Giang Long Tran on 30.03.2023.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    public static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
