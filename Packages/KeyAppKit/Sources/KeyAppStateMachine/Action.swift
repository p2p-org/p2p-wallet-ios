import Foundation

/// Requirement for an action in a `StateMachine`.
/// Action needs to be lightweight struct that holds the name of the action and parameters needed for performing this action.
/// Action should be Equatable (to support reverse, comparison, ignoring duplication, etc.).
public protocol Action: Equatable {
    
}
