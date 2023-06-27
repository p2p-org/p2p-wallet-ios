//
// Created by Giang Long Tran on 05.05.2022.
//

import Foundation

public extension Task where Success == Never, Failure == Never {
    static var isNotCancelled: Bool { !Task.isCancelled }
}
