//
//  TransakWidgetViewController+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/07/2021.
//

import Foundation
import TransakSwift

extension TransakWidgetViewController {
    struct CryptoCurrency: OptionSet {
        let rawValue: Int
        
        static let usdc = CryptoCurrency(rawValue: 1 << 0)
        static let sol = CryptoCurrency(rawValue: 1 << 1)
        static var all: Self {[usdc, sol]}
        
        var code: String {
            switch self {
            case .usdc:
                return "USDC"
            case .sol:
                return "SOL"
            case .all:
                return "USDC,SOL"
            default:
                fatalError()
            }
        }
    }
}

extension WLSpinnerView: TransakWidgetLoadingView {
    public func startLoading() {
        animate()
    }
    public func stopLoading() {
        stopAnimating()
    }
}
