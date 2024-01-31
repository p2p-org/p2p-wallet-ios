import Foundation
import SolanaSwift

public enum SolanaAddressInfo {
    case empty
    case splAccount(TokenAccountState)
}

extension SolanaAddressInfo: BufferLayout {
    public init(from reader: inout SolanaSwift.BinaryReader) throws {
        if reader.isEmpty {
            self = .empty
        } else if let accountInfo = try? TokenAccountState(from: &reader) {
            self = .splAccount(accountInfo)
        } else {
            self = .empty
        }
    }

    public func serialize(to writer: inout Data) throws {
        switch self {
        case let .splAccount(info):
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
            throw BinaryReaderError.dataMismatch
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
