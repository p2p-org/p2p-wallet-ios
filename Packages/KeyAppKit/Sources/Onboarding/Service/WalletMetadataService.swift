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
    func synchronize() async
    
    func update(_ newMetadata: WalletMetaData) async

    var metadata: AsyncValueState<WalletMetaData?> { get }

    var metadataPublisher: AnyPublisher<AsyncValueState<WalletMetaData?>, Never> { get }
}
