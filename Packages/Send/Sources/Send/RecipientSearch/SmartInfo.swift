// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public enum SolanaAddressInfo {
    case empty
    case splAccount(AccountInfo)
}

extension SolanaAddressInfo: BufferLayout {
    public init(from reader: inout SolanaSwift.BinaryReader) throws {
        if reader.isEmpty {
            self = .empty
        } else if let accountInfo = try? AccountInfo.init(from: &reader) {
            self = .splAccount(accountInfo)
        } else {
            self = .empty
        }
    }
    
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .splAccount(let info):
            try info.serialize(to: &writer)
        default:
            return
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Unable to get parsed data, fallback to decoding base64
        let stringData = (try? container.decode([String].self).first) ?? (try? container.decode(String.self))
        guard let string = stringData else {
            throw SolanaError.couldNotRetrieveAccountInfo
        }

        if string.isEmpty, !(Self.self == EmptyInfo.self) {
            self = .empty
            return
        }

        let data = Data(base64Encoded: string) ?? Data(Base58.decode(string))

        var reader = BinaryReader(bytes: data.bytes)
        try self.init(from: &reader)
    }
}
