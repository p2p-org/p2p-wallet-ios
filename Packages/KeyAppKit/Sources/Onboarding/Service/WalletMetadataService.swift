//
//  File.swift
//
//
//  Created by Giang Long Tran on 15/06/2023.
//

import Combine
import Foundation
import KeyAppKitCore

public protocol WalletMetadataService {
    func synchronize() async throws

    var metadata: AsyncValueState<WalletMetaData?> { get }

    var metadataPublisher: AnyPublisher<AsyncValueState<WalletMetaData?>, Never> { get }
}
