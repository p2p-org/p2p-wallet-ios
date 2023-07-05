import Foundation

/// A event struct that represent an event in a `StateMachine`.
/// Event needs to be lightweight that holds the name of the event and parameters needed for performing an action.
/// Event should be Equatable (to support reverse, comparison, ignoring duplication, etc.).
public protocol Event: Equatable {
    
}
