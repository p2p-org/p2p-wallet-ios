import Foundation
import KeyAppStateMachine

public enum NSendInputAction: Action {
    case calculate(input: NSendInput)

    case fetch
}
