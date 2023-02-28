//
// Created by Giang Long Tran on 19.04.2022.
//

import Foundation
import RxCocoa
import RxSwift

/// Refreshing history depends on coming signal.
protocol HistoryRefreshTrigger {
    /// Registers a trigger
    ///
    /// - Returns: A stream of refreshing signal
    func register() -> Signal<Void>
}
