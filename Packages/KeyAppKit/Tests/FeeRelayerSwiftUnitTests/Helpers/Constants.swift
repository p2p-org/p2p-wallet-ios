import SolanaSwift
@testable import OrcaSwapSwift

let minimumTokenAccountBalance: UInt64 = 2039280
let minimumRelayAccountBalance: UInt64 = 890880
let lamportsPerSignature: UInt64 = 5000
let blockhash: String = "CSymwgTNX1j3E4qhKfJAUE41nBWEwXufoYryPbkde5RR"

extension PublicKey {
    static var owner: PublicKey {
        "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG"
    }
    
    static var feePayerAddress: PublicKey {
        "FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT"
    }
    
    static var usdcAssociatedAddress: PublicKey {
        "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3"
    }
    
    static var usdtMint: PublicKey {
        "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB"
    }
    
    static var btcMint: PublicKey {
        "9n4nbM75f5Ui33ZbPYXn59EwSgE8CGsHtAeTH5YFeJ9E"
    }
    
    static var btcAssociatedAddress: PublicKey {
        "4Vfs3NZ1Bo8agrfBJhMFdesso8tBWyUZAPBGMoWHuNRU"
    }

    static var ethMint: PublicKey {
        "2FPyTwcZLUg1MDrwsyoP4D6s1tM7hAkHYRjkNb5w6Pxk"
    }
    static var ethAssociatedAddress: PublicKey {
        "4Tz8MH5APRfA4rjUNxhRruqGGMNvrgji3KhWYKf54dc7"
    }

    static var btcTransitTokenAccountAddress: PublicKey {
        "8eYZfAwWoEfsNMmXhCPUAiTpG8EzMgzW8nzr7km3sL2s"
    }
    
    static var swapProgramId: PublicKey {
        "9W959DqEETiGZocYWCQPaJ6sBmUzgfxXfqGeTEdp3aQP"
    }
    
    static var deprecatedSwapProgramId: PublicKey {
        "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1"
    }
    
    static var relayAccount: PublicKey {
        "CgbNQZHjhRWf2VQ96YfVLTsL9abwEuFuTM63G8Yu4KYo"
    }
    
    static var relayTemporaryWSOLAccount: PublicKey {
        "6VfQe3pQpE6mDDsjeertA5USua5hJx2d9c86UymQaJjr"
    }
}

extension Pool {
    static var solBTC: Pool {
        .init(
            account: "7N2AEJ98qBs4PwEwZ6k5pj8uZBKMkZrKZeiC7A64B47u",
            authority: "GqnLhu3bPQ46nTZYNFDnzhwm31iFoqhi3ntXMtc5DPiT",
            nonce: 255,
            poolTokenMint: "Acxs19v6eUMTEfdvkvWkRB4bwFCHm3XV9jABCy7c1mXe",
            tokenAccountA: "5eqcnUasgU2NRrEAeWxvFVRTTYWJWfAJhsdffvc6nJc2",
            tokenAccountB: "9G5TBPbEUg2iaFxJ29uVAT8ZzxY77esRshyHiLYZKRh8",
            feeAccount: "4yPG4A9jB3ibDMVXEN2aZW4oA1e1xzzA3z5VWjkZd18B",
            hostFeeAccount: nil,
            feeNumerator: 25,
            feeDenominator: 10000,
            ownerTradeFeeNumerator: 5,
            ownerTradeFeeDenominator: 10000,
            ownerWithdrawFeeNumerator: 0,
            ownerWithdrawFeeDenominator: 0,
            hostFeeNumerator: 0,
            hostFeeDenominator: 0,
            tokenAName: "SOL",
            tokenBName: "BTC",
            curveType: "ConstantProduct",
            amp: nil,
            programVersion: 2,
            deprecated: nil,
            tokenABalance: .init(amount: "715874535300", decimals: 9),
            tokenBBalance: .init(amount: "1113617", decimals: 6),
            isStable: nil
        )
    }

    static var btcETH: Pool {
        .init(
            account: "Fz6yRGsNiXK7hVu4D2zvbwNXW8FQvyJ5edacs3piR1P7",
            authority: "FjRVqnmAJgzjSy2J7MtuQbbWZL3xhZUMqmS2exuy4dXF",
            nonce: 255,
            poolTokenMint: "8pFwdcuXM7pvHdEGHLZbUR8nNsjj133iUXWG6CgdRHk2",
            tokenAccountA: "81w3VGbnszMKpUwh9EzAF9LpRzkKxc5XYCW64fuYk1jH",
            tokenAccountB: "6r14WvGMaR1xGMnaU8JKeuDK38RvUNxJfoXtycUKtC7Z",
            feeAccount: "56FGbSsbZiP2teQhTxRQGwwVSorB2LhEGdLrtUQPfFpb",
            hostFeeAccount: nil,
            feeNumerator: 30,
            feeDenominator: 10000,
            ownerTradeFeeNumerator: 0,
            ownerTradeFeeDenominator: 0,
            ownerWithdrawFeeNumerator: 0,
            ownerWithdrawFeeDenominator: 0,
            hostFeeNumerator: 0,
            hostFeeDenominator: 0,
            tokenAName: "BTC",
            tokenBName: "ETH",
            curveType: "ConstantProduct",
            amp: nil,
            programVersion: nil,
            deprecated: true,
            tokenABalance: .init(amount: "786", decimals: 6),
            tokenBBalance: .init(amount: "9895", decimals: 6),
            isStable: nil
        )
    }
    
    static var ethSOL: Pool {
        .init(
            account: "4vWJYxLx9F7WPQeeYzg9cxhDeaPjwruZXCffaSknWFxy",
            authority: "Hmjv9wvRctYXHRaX7dTdHB4MsFk4mZgKQrqrgQJXNXii",
            nonce: 252,
            poolTokenMint: "7bb88DAnQY7LSoWEuqezCcbk4vutQbuRqgJMqpX8h6dL",
            tokenAccountA: "FidGus13X2HPzd3cuBEFSq32UcBQkF68niwvP6bM4fs2",
            tokenAccountB: "5x1amFuGMfUVzy49Y4Pc3HyCVD2usjLaofnzB3d8h7rv",
            feeAccount: "CYGRBB4qAYzSqdnvVaXvyZLg5j7YNVcuqM6gdD2MMUi1",
            hostFeeAccount: nil,
            feeNumerator: 30,
            feeDenominator: 10000,
            ownerTradeFeeNumerator: 0,
            ownerTradeFeeDenominator: 0,
            ownerWithdrawFeeNumerator: 0,
            ownerWithdrawFeeDenominator: 0,
            hostFeeNumerator: 0,
            hostFeeDenominator: 0,
            tokenAName: "ETH",
            tokenBName: "SOL",
            curveType: "ConstantProduct",
            amp: nil,
            programVersion: nil,
            deprecated: true,
            tokenABalance: .init(amount: "710916", decimals: 6),
            tokenBBalance: .init(amount: "10092481679", decimals: 9),
            isStable: nil
        )
    }
    
    static var solUSDC: Pool {
        .init(
            account: "6fTRDD7sYxCN7oyoSQaN1AWC3P2m8A6gVZzGrpej9DvL",
            authority: "B52XRdfTsh8iUGbGEBJLHyDMjhaTW8cAFCmpASGJtnNK",
            nonce: 253,
            poolTokenMint: "ECFcUGwHHMaZynAQpqRHkYeTBnS5GnPWZywM8aggcs3A",
            tokenAccountA: "FdiTt7XQ94fGkgorywN1GuXqQzmURHCDgYtUutWRcy4q",
            tokenAccountB: "7VcwKUtdKnvcgNhZt5BQHsbPrXLxhdVomsgrr7k2N5P5",
            feeAccount: "4pdzKqAGd1WbXn1L4UpY4r58irTfjFYMYNudBrqbQaYJ",
            hostFeeAccount: nil,
            feeNumerator: 30,
            feeDenominator: 10000,
            ownerTradeFeeNumerator: 0,
            ownerTradeFeeDenominator: 0,
            ownerWithdrawFeeNumerator: 0,
            ownerWithdrawFeeDenominator: 0,
            hostFeeNumerator: 0,
            hostFeeDenominator: 0,
            tokenAName: "SOL",
            tokenBName: "USDC",
            curveType: "ConstantProduct",
            amp: nil,
            programVersion: nil,
            deprecated: true,
            tokenABalance: .init(amount: "706218408046", decimals: 9),
            tokenBBalance: .init(amount: "16374219298", decimals: 6),
            isStable: nil
        )
    }
    
    static var usdcUSDT: Pool {
        .init(
            account: "8KZjKCNTshjwapD4TjWQonXBdi1Jm4Eks5rgrViK9UCx",
            authority: "6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D",
            nonce: 253,
            poolTokenMint: "3H5XKkE9uVvxsdrFeN4BLLGCmohiQN6aZJVVcJiXQ4WC",
            tokenAccountA: "EDukSdAegSUtKsGi6wdKTpaBuYK9ZcVj9Uz1f39ffdgi",
            tokenAccountB: "9oaFyrMCwxKE6kBQRP5v9Jo5Uh39Y5p2fFaqGtcxnjYr",
            feeAccount: "EDuiPgd4PuCXe9h2YieMbH7uUMeB4pgeWnP5hfcPvxu3",
            hostFeeAccount: nil,
            feeNumerator: 30,
            feeDenominator: 10000,
            ownerTradeFeeNumerator: 0,
            ownerTradeFeeDenominator: 0,
            ownerWithdrawFeeNumerator: 0,
            ownerWithdrawFeeDenominator: 0,
            hostFeeNumerator: 0,
            hostFeeDenominator: 0,
            tokenAName: "USDC",
            tokenBName: "USDT",
            curveType: "ConstantProduct",
            amp: nil,
            programVersion: nil,
            deprecated: true,
            tokenABalance: .init(amount: "4705722687", decimals: 6),
            tokenBBalance: .init(amount: "4710077640", decimals: 6),
            isStable: nil
        )
    }
    
    static var solUSDT: Pool {
        .init(
            account: "4bS6bkBdJ4B1Bt4ft3oGF8La7eKpCqz8xnu1AMpMxWSP",
            authority: "EAvLj3zW236pUSSSzwjL18QuPpkTxkWaVSR5GdX7yiNa",
            nonce: 255,
            poolTokenMint: "BmZNYGt7aApGTUUxAQUYsW64cMbb6P7uniokCWaptj4D",
            tokenAccountA: "BBDQmitNga99M9QsBRnyos9uWPumNbWLC1mfbReJi45C",
            tokenAccountB: "8xepSs1iXsSw8QrCS1rpZk8KY3fMwUZqDT4dmzDa2trX",
            feeAccount: "HR2rWgcU6SNCWxJDozDu6qCgSSvUoKCynbhQPGRNqpCG",
            hostFeeAccount: nil,
            feeNumerator: 30,
            feeDenominator: 10000,
            ownerTradeFeeNumerator: 0,
            ownerTradeFeeDenominator: 0,
            ownerWithdrawFeeNumerator: 0,
            ownerWithdrawFeeDenominator: 0,
            hostFeeNumerator: 0,
            hostFeeDenominator: 0,
            tokenAName: "SOL",
            tokenBName: "USDT",
            curveType: "ConstantProduct",
            amp: nil,
            programVersion: nil,
            deprecated: true,
            tokenABalance: .init(amount: "85484159388", decimals: 9),
            tokenBBalance: .init(amount: "2067442317", decimals: 6),
            isStable: nil
        )
    }
}

extension String {
    var publicKey: PublicKey {
        try! toPublicKey()
    }
}
