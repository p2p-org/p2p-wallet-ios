import Foundation
import SolanaSwift

extension SwapTransactionBuilderImpl {
    func checkSigners(
        ownerAccount: KeyPair,
        env: inout SwapTransactionBuilderOutput
    ) {
        env.signers.append(ownerAccount)
        if let sourceWSOLNewAccount = env.sourceWSOLNewAccount { env.signers.append(sourceWSOLNewAccount) }
        if let destinationNewAccount = env.destinationNewAccount { env.signers.append(destinationNewAccount) }
    }
}
