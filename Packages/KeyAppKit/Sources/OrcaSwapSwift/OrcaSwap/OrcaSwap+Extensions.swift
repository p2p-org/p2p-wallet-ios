import Foundation
import SolanaSwift

extension OrcaSwap {
    func getPools(
        forRoute route: Route,
        fromTokenName: String,
        toTokenName: String
    ) async throws -> [Pool] {
        guard !route.isEmpty else { return [] }

        var pools = [Pool]()
        try await withThrowingTaskGroup(of: Pool?.self) { group in
            for path in route {
                group.addTask {
                    try await self.fixedPool(path: path)
                }
            }
            for try await pool in group {
                guard let pool = pool else { continue }
                pools.append(pool)
            }
        }

        // modify orders
        if pools.count == 2 {
            // reverse order of the 2 pools
            // Ex: Swap from SOCN -> BTC, but paths are
            // [
            //     "BTC/SOL[aquafarm]",
            //     "SOCN/SOL[stable][aquafarm]"
            // ]
            // Need to change to
            // [
            //     "SOCN/SOL[stable][aquafarm]",
            //     "BTC/SOL[aquafarm]"
            // ]

            if pools[0].tokenAName != fromTokenName, pools[0].tokenBName != fromTokenName {
                let temp = pools[0]
                pools[0] = pools[1]
                pools[1] = temp
            }
        }

        // reverse token A and token B in pool if needed
        for i in 0 ..< pools.count {
            if i == 0 {
                var pool = pools[0]
                if pool.tokenAName.fixedTokenName != fromTokenName.fixedTokenName {
                    pool = pool.reversed
                }
                pools[0] = pool
            }

            if i == 1 {
                var pool = pools[1]
                if pool.tokenBName.fixedTokenName != toTokenName.fixedTokenName {
                    pool = pool.reversed
                }
                pools[1] = pool
            }
        }
        return pools
    }

    private func fixedPool(
        path: String // Ex. BTC/SOL[aquafarm][stable]
    ) async throws -> Pool? {
        guard let allPools = info?.pools, var pool = allPools[path] else { return nil }

        if path.contains("[stable]") {
            pool.isStable = true
        }

        // get balances
        let (tokenABalance, tokenBBalance): (TokenAccountBalance, TokenAccountBalance)
        if let tab = await balancesCache.getTokenABalance(pool: pool),
           let tbb = await balancesCache.getTokenBBalance(pool: pool)
        {
            (tokenABalance, tokenBBalance) = (tab, tbb)
        } else {
            try Task.checkCancellation()
            let pool = pool
            async let tokenABalanceResult = solanaClient.getTokenAccountBalance(
                pubkey: pool.tokenAccountA,
                commitment: nil
            )
            async let tokenBBalanceResult = solanaClient.getTokenAccountBalance(
                pubkey: pool.tokenAccountB,
                commitment: nil
            )
            (tokenABalance, tokenBBalance) = try await(tokenABalanceResult, tokenBBalanceResult)
        }

        await balancesCache.save(key: pool.tokenAccountA, value: tokenABalance)
        await balancesCache.save(key: pool.tokenAccountB, value: tokenBBalance)

        pool.tokenABalance = tokenABalance
        pool.tokenBBalance = tokenBBalance

        // get minrent exemption
        let (tokenAMinRent, tokenBMinRent): (UInt64, UInt64)
        if let tab = await minRentCache.getTokenABalance(pool: pool),
           let tbb = await minRentCache.getTokenBBalance(pool: pool)
        {
            (tokenAMinRent, tokenBMinRent) = (tab, tbb)
        } else {
            try Task.checkCancellation()
            let pool = pool
            async let tokenAMinRentResult: BufferInfo<SPLTokenAccountState>? = solanaClient
                .getAccountInfo(account: pool.tokenAccountA)
            async let tokenBMinRentResult: BufferInfo<SPLTokenAccountState>? = solanaClient
                .getAccountInfo(account: pool.tokenAccountB)
            (tokenAMinRent, tokenBMinRent) = try await(
                tokenAMinRentResult?.lamports ?? 2_039_280,
                tokenBMinRentResult?.lamports ?? 2_039_280
            )
        }

        await minRentCache.save(key: pool.tokenAccountA, value: tokenAMinRent)
        await minRentCache.save(key: pool.tokenAccountB, value: tokenBMinRent)

        pool.tokenAMinimumBalanceForRentExemption = tokenAMinRent
        pool.tokenBMinimumBalanceForRentExemption = tokenBMinRent

        return pool
    }
}

private extension String {
    /// Convert  SOL[aquafarm] to SOL
    var fixedTokenName: String {
        components(separatedBy: "[").first!
    }
}
