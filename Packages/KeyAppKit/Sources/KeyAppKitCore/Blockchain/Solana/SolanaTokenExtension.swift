// import Foundation
// import SolanaSwift
//
// public extension SolanaToken {
//    var keyAppExtensions: KeyAppTokenExtension {
//        KeyAppTokenExtension(data: extensions ?? [:])
//    }
// }
//
// public struct KeyAppTokenExtension: Codable, Hashable {
//    public let ruleOfProcessingTokenPriceWS: RuleOfProcessingTokenPriceWS?
//    public let isPositionOnWS: Bool?
//    public let isTokenCellVisibleOnWS: Bool
//    public let percentDifferenceToShowByPriceOnWS: Double?
//    public let calculationOfFinalBalanceOnWS: Bool?
//    public let ruleOfFractionalPartOnWS: RuleOfFractionalPartOnWS?
//    public let canBeHidden: Bool
//
//    public enum RuleOfProcessingTokenPriceWS: String, Codable, Hashable {
//        case byCountOfTokensValue
//    }
//
//    public enum RuleOfFractionalPartOnWS: String, Codable, Hashable {
//        case droppingAfterHundredthPart
//    }
//
//    init(data: [String: TokenExtensionValue]) {
//        isPositionOnWS = data["isPositionOnWS"]?.boolValue
//        isTokenCellVisibleOnWS = data["isTokenCellVisibleOnWS"]?.boolValue ?? true
//        calculationOfFinalBalanceOnWS = data["calculationOfFinalBalanceOnWS"]?.boolValue
//        percentDifferenceToShowByPriceOnWS = data["percentDifferenceToShowByPriceOnWS"]?.doubleValue
//        canBeHidden = data["canBeHidden"]?.boolValue ?? true
//
//        if data["ruleOfProcessingTokenPriceWS"]?.stringValue == "byCountOfTokensValue" {
//            ruleOfProcessingTokenPriceWS = .byCountOfTokensValue
//        } else {
//            ruleOfProcessingTokenPriceWS = nil
//        }
//
//        if data["ruleOfFractionalPartOnWS"]?.stringValue == "droppingAfterHundredthPart" {
//            ruleOfFractionalPartOnWS = .droppingAfterHundredthPart
//        } else {
//            ruleOfFractionalPartOnWS = nil
//        }
//    }
//
//    public init(
//        ruleOfProcessingTokenPriceWS: KeyAppTokenExtension.RuleOfProcessingTokenPriceWS? = nil,
//        isPositionOnWS: Bool? = nil,
//        isTokenCellVisibleOnWS: Bool? = nil,
//        percentDifferenceToShowByPriceOnWS: Double? = nil,
//        calculationOfFinalBalanceOnWS: Bool? = nil,
//        ruleOfFractionalPartOnWS: KeyAppTokenExtension.RuleOfFractionalPartOnWS? = nil,
//        canBeHidden: Bool? = nil
//    ) {
//        self.ruleOfProcessingTokenPriceWS = ruleOfProcessingTokenPriceWS
//        self.isPositionOnWS = isPositionOnWS
//        self.isTokenCellVisibleOnWS = isTokenCellVisibleOnWS ?? true
//        self.percentDifferenceToShowByPriceOnWS = percentDifferenceToShowByPriceOnWS
//        self.calculationOfFinalBalanceOnWS = calculationOfFinalBalanceOnWS
//        self.ruleOfFractionalPartOnWS = ruleOfFractionalPartOnWS
//        self.canBeHidden = canBeHidden ?? true
//    }
// }
