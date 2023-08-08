import Foundation

/// A state struct that represent a state in a `StateMachine`.
/// State should be self-immutable, every actions/event will receive old state, copy it, calculate and return new state.
/// State needs to be **lightweight**. It contains mutable properties and computed properties. Every time you want to
/// add a property to a state, you need to clearly define weather it is mutable property or computed property.
/// State should be Equatable (to support reverse, comparison, ignoring duplication, etc.).
public protocol State: Equatable {}

/// Common extension for `State`
public extension State {
    /// Convenience method to copy current state and modify it to return a new state.
    /// - Parameter modify: modify logic
    /// - Returns: new state
    func modified(_ modify: (inout Self) -> Void) -> Self {
        var state = self
        modify(&state)
        return state
    }
}
