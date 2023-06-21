import Combine
import Foundation
import SolanaSwift
import TweetNacl

/// Protocol for current user
public protocol CurrentUserWallet: AnyObject {
    var value: UserWallet? { get }
    var valuePublisher: AnyPublisher<UserWallet?, Never> { get }
}

public class MockCurrentUserWallet: CurrentUserWallet {
    public let value: UserWallet?

    public var valuePublisher: AnyPublisher<UserWallet?, Never> {
        CurrentValueSubject(value)
            .eraseToAnyPublisher()
    }

    public init(_ value: UserWallet) {
        self.value = value
    }

    public static func random() -> MockCurrentUserWallet {
        let mnemonic = Mnemonic()

        let keys = try! Ed25519HDKey.derivePath(DerivablePath.default.rawValue, seed: mnemonic.seed.toHexString()).get()
        let keyPair = try! NaclSign.KeyPair.keyPair(fromSeed: keys.key)
        let newKey = try! PublicKey(data: keyPair.publicKey)

        let account = KeyPair(phrase: mnemonic.phrase, publicKey: newKey, secretKey: keyPair.secretKey)
        let ethereumKeyPair = try! EthereumKeyPair(phrase: account.phrase.joined(separator: " "))

        let randomUser = UserWallet(
            seedPhrase: mnemonic.phrase,
            derivablePath: .default,
            name: nil,
            ethAddress: nil,
            account: account,
            moonpayExternalClientId: nil,
            ethereumKeypair: ethereumKeyPair
        )

        return MockCurrentUserWallet(randomUser)
    }
}
