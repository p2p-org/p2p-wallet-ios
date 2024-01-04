import Foundation
import SolanaSwift
import TweetNacl

func extractOnboardingSeedPhrase(phrase: String, path: String) throws -> Data {
    let mnemonic = try Mnemonic(phrase: phrase.components(separatedBy: " "))
    let secretKey = try Ed25519HDKey.derivePath(path, seed: mnemonic.seed.toHexString()).get().key
    let keyPair = try NaclSign.KeyPair.keyPair(fromSeed: secretKey)
    let result = keyPair.secretKey.prefix(32)
    return result
}
