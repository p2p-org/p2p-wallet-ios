//
// Created by Giang Long Tran on 05.05.2022.
//

import Foundation
import SolanaSwift

extension SolanaTokensRepository {
  func getTokenWithMint(_ mint: String?) async throws -> Token {
    guard let mint = mint else {
      return .unsupported(mint: nil)
    }
    
    let tokens = try await getTokensList()
    
    // Special case, we need take SOL not wSOL from repository.
    if mint == "So11111111111111111111111111111111111111112" {
      return tokens.first { $0.address == mint && $0.symbol == "SOL" } ?? .unsupported(mint: mint)
    } else {
      return tokens.first { $0.address == mint } ?? .unsupported(mint: mint)
    }
  }
}
