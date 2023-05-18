//
//  File.swift
//
//
//  Created by Giang Long Tran on 30.03.2023.
//

import Foundation

public enum UserActionStatus: Codable, Equatable {
    /// Action is waiting to perform.
    case pending

    /// Action is in progress.
    case processing

    /// Action is finished.
    case ready

    /// Action occurs error.
    case error(UserActionError)
}

public protocol UserAction: Codable, Equatable {
    /// Unique internal id to track.
    var id: String { get }

    /// Abstract status.
    var status: UserActionStatus { get }

    var createdDate: Date { get }

    var updatedDate: Date { get set }
}

