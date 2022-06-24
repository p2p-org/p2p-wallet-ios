//
// Created by Giang Long Tran on 22.03.2022.
//

import Foundation
import SolanaSwift

enum KeyPhrase {
    static func checkPhrase(in words: [String]) -> (status: Bool, error: String?) {
        guard words.count >= 12 else {
            return (false, L10n.seedPhraseMustHaveAtLeast12Words)
        }

        do {
            _ = try Mnemonic(phrase: words)
            return (true, nil)
        } catch {
            return (false, L10n.wrongOrderOrSeedPhrasePleaseCheckItAndTryAgain)
        }
    }
}
