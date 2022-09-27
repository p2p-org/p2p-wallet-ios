import Foundation

struct JWTTokenIDModel: Codable {
    let iat: Date
    let email: String
}

protocol JWTTokenValidator {
    func decode(tokenID: String) -> JWTTokenIDModel?
}

final class JWTTokenValidatorImpl: JWTTokenValidator {
    func decode(tokenID: String) -> JWTTokenIDModel? {
        decode(token: tokenID) as JWTTokenIDModel?
    }

    private func decode<T: Codable>(token: String) -> T? {
        let jwtComponents = token.split(separator: ".").map { String($0) }

        // Validate token structure
        guard jwtComponents.count == 3 else {
            return nil
        }

        // Parse components
        let payload = decode(base64UrlString: jwtComponents[1])

        let string = payload.replacingOccurrences(of: "\\\"", with: "\"").replacingOccurrences(of: "\"{", with: "{")
            .replacingOccurrences(of: "}\"", with: "}")
        var model: T?
        if let data = string.data(using: .utf8) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            model = try? decoder.decode(T.self, from: data)
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

    private func convertToBase64Url(from base64: String) -> String {
        // Character '=' is optional, '_' for '/', '-' for '+'
        base64.replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
    }
}
