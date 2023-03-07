//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import Combine
import KeyAppKitCore

public final class EthereumAccountsService: NSObject, ObservableObject {
    private var subscriptions = [AnyCancellable]()

//    private let asyncValue: AsyncValue<[Account]>

//    @Published public var state: AsyncValueState<[Account]> = .init(value: [])

    public init(
        priceService: PriceService,
        fiat: String
    ) {}
}
