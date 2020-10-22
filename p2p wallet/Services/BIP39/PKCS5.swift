//
//  PKCS5.swift
//  
//
//  Created by Liu Pengpeng on 2019/10/10.
//

import Foundation
import CryptoKit
import CommonCrypto

public struct PKCS5 {
    public enum Error: Swift.Error {
        case invalidInput
    }
    
    public static func PBKDF2SHA512(password: String, salt: String, iterations: Int = 2048, keyLength: Int = 64) throws -> Array<UInt8> {
        var bytes = [UInt8](repeating: 0, count: keyLength)

        try bytes.withUnsafeMutableBytes { (outputBytes: UnsafeMutableRawBufferPointer) in
            let status = CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                password,
                password.utf8.count,
                salt,
                salt.utf8.count,
                CCPBKDFAlgorithm(kCCPRFHmacAlgSHA512),
                UInt32(iterations),
                outputBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                keyLength
            )
            guard status == kCCSuccess else {
                throw Error.invalidInput
            }
        }
        return bytes
    }
}
