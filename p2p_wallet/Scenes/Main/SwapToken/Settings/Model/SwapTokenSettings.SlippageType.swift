//
//  SwapTokenSettings.SlippageType.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.12.2021.
//

extension SwapTokenSettings {
    enum SlippageType: CustomStringConvertible, CaseIterable, Equatable {
        static var allCases: [SwapTokenSettings.SlippageType] {
            [.oneTenth, .fiveTenth, .one, .custom(nil)]
        }

        case oneTenth
        case fiveTenth
        case one
        case custom(Double?)

        init(doubleValue: Double) {
            switch doubleValue {
            case 0.001:
                self = .oneTenth
            case 0.005:
                self = .fiveTenth
            case 0.01:
                self = .one
            default:
                self = .custom(doubleValue * 100)
            }
        }

        var description: String {
            switch self {
            case .oneTenth:
                return "0.1%"
            case .fiveTenth:
                return "0.5%"
            case .one:
                return "1%"
            case .custom:
                return L10n.custom
            }
        }

        var doubleValue: Double? {
            let slippage: Double?

            switch self {
            case .oneTenth:
                slippage = 0.1
            case .fiveTenth:
                slippage = 0.5
            case .one:
                slippage = 1
            case let .custom(double):
                slippage = double
            }

            return slippage.map { $0 / 100 }
        }
    }
}
