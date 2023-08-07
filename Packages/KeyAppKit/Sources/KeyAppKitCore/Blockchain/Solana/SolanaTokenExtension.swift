import Foundation
import SolanaSwift

public extension SolanaToken {
    var keyAppExtensions: KeyAppTokenExtension {
        KeyAppTokenExtension(data: extensions ?? [:])
    }
}

public struct KeyAppTokenExtension: Codable, Equatable {
    public let ruleOfProcessingTokenPriceWS: RuleOfProcessingTokenPriceWS?
    public let isPositionOnWS: Bool?
    public let isTokenCellVisibleOnWS: Bool
    public let percentDifferenceToShowByPriceOnWS: Int?
    public let calculationOfFinalBalanceOnWS: Bool?
    public let ruleOfFractionalPartOnWS: RuleOfFractionalPartOnWS?
    public let canBeHidden: Bool?

    public enum RuleOfProcessingTokenPriceWS: String, Codable, Equatable {
        case byCountOfTokensValue
    }

    public enum RuleOfFractionalPartOnWS: String, Codable, Equatable {
        case droppingAfterHundredthPart
    }

    init(data: [String: TokenExtensionValue]) {
        isPositionOnWS = data["isPositionOnWS"]?.boolValue
        isTokenCellVisibleOnWS = data["isTokenCellVisibleOnWS"]?.boolValue ?? true
        calculationOfFinalBalanceOnWS = data["calculationOfFinalBalanceOnWS"]?.boolValue
        percentDifferenceToShowByPriceOnWS = data["percentDifferenceToShowByPriceOnWS"]?.intValue
        canBeHidden = data["canBeHidden"]?.boolValue

        if data["ruleOfProcessingTokenPriceWS"]?.stringValue == "byCountOfTokensValue" {
            ruleOfProcessingTokenPriceWS = .byCountOfTokensValue
        } else {
            ruleOfProcessingTokenPriceWS = nil
        }

        if data["ruleOfFractionalPartOnWS"]?.stringValue == "droppingAfterHundredthPart" {
            ruleOfFractionalPartOnWS = .droppingAfterHundredthPart
        } else {
            ruleOfFractionalPartOnWS = nil
        }
    }
}
