//
//  JWTTokenValidator.swift
//  User
//
//  Created by Elizaveta Semyonova on 20/08/2019.
//

import Foundation

final class JWTTokenUserModel: Codable {
    let iat: Int
}

protocol JWTTokenValidatorProtocol {
    func decode(tokenID: String) -> JWTTokenUserModel?
}

class JWTTokenValidator: JWTTokenValidatorProtocol {
    private enum Errors: String {
        case invalidComponentsCount = "Invalid JWT token components count"
        case unverifiedSignature = "JWT token signature is not verified"
    }

    func decode(tokenID: String) -> JWTTokenUserModel? {
        decode(token: tokenID) as JWTTokenUserModel?
    }

    private func decode<T: Codable>(token: String) -> T? {
        let jwtComponents = token.split(separator: ".").map { String($0) }

        // Проверяем структуру токена
        guard jwtComponents.count == 3 else {
            return nil
        }

        // Парсим отдельные компоненты
        let payload = decode(base64UrlString: jwtComponents[1])

        let string = payload.replacingOccurrences(of: "\\\"", with: "\"").replacingOccurrences(of: "\"{", with: "{")
            .replacingOccurrences(of: "}\"", with: "}")
        var model: T?
        if let data = string.data(using: .utf8) {
            model = try? JSONDecoder().decode(T.self, from: data)
        }
        return model
    }

    private func decode(base64UrlString: String) -> String {
        var base64String = base64UrlString.replacingOccurrences(of: "_", with: "/")
            .replacingOccurrences(of: "-", with: "+")
        let length = Double(base64String.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64String += padding
        }
        guard let resultData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else { return "" }
        return String(data: resultData, encoding: .utf8) ?? ""
    }

    /// Конвертирует base64 в base64Url
    private func convertToBase64Url(from base64: String) -> String {
        /// Character '=' is optional, '_' for '/', '-' for '+'
        base64.replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
    }
}