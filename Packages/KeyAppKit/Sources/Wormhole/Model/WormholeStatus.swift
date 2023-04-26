//
//  File.swift
//  
//
//  Created by Giang Long Tran on 11.04.2023.
//

import Foundation

public enum WormholeStatus: String, Codable, Hashable, Equatable {
    case failed
    case pending
    case expired
    case canceled
    case inProgress = "in_progress"
    case completed
}
