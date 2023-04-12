//
//  File.swift
//  
//
//  Created by Giang Long Tran on 29.03.2023.
//

import Foundation

public struct SendTransaction: Hashable, Codable {
    public let transaction: String
    public let message: String
}
