// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public extension SolendConfigAsset {
    enum Mock {
        public static let sol: SolendConfigAsset = .init(
            name: "Wrapped SOL",
            symbol: "SOL",
            decimals: 9,
            mintAddress: "So11111111111111111111111111111111111111112",
            logo: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png"
        )
        public static let usdc: SolendConfigAsset = .init(
            name: "USDC",
            symbol: "USD Coin",
            decimals: 6,
            mintAddress: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            logo: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v/logo.png"
        )
        public static let btc: SolendConfigAsset = .init(
            name: "Wrapped Bitcoin (Sollet)",
            symbol: "BTC",
            decimals: 9,
            mintAddress: "9n4nbM75f5Ui33ZbPYXn59EwSgE8CGsHtAeTH5YFeJ9E",
            logo: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/9n4nbM75f5Ui33ZbPYXn59EwSgE8CGsHtAeTH5YFeJ9E/logo.png"
        )
    }
}
