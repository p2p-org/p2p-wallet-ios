//
//  Fileswift
//
//
//  Created by Giang Long Tran on 07032023
//

import Foundation
import Web3

public enum EthereumAddresses {
    public enum ERC20: String, CaseIterable {
        case sol = "0xd31a59c85ae9d8edefec411d448f90841571b89c"
        case bnb = "0x418d75f65a02b3d53b2418fb8e1fe493759c7605"
        case usdc = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        case usdt = "0xdac17f958d2ee523a2206206994597c13d831ec7"
        case eth = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
        case dai = "0x6b175474e89094c44da98b954eedeac495271d0f"
        case wbtc = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599"
        case usdk = "0x1c48f86ae57291f7686349f12601910bd8d470bb"
        case frax = "0x853d955acef822db058eb8505911ed77f175b99e"
        case shib = "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce"
        case sushi = "0x6b3595068778dd592e39a122f4f5a5cf09c90fe2"
        case dydx = "0x92d6c1e31e14520e676a687f0a93788b716beff5"
        case mana = "0x0f5d2fb29fb7d3cfee444a200298f468908cc942"
        case sand = "0x3845badade8e6dff049820680d1f14bd3903a5d0"
        case uni = "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984"
        case ldo = "0x5a98fcbea516cf06857215779fd812ca3bef1b32"
        case hxro = "0x4bd70556ae3f8a6ec6c4080a0c327b24325438f3"
    }
}
