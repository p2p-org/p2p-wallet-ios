//
//  TransactionActivityAttributes.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 18.09.2022.
//

import SwiftUI
import ActivityKit

public struct TransactionActivityAttributes: ActivityAttributes {
    public typealias TimeState = ContentState

    public struct ContentState: Codable, Hashable {
        var status: String
        var deliveryTimer: ClosedRange<Date>
    }

    var transactionID: String
    var transactionDescription: String
}
