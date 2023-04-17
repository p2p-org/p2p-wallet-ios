///
/// `TransitionContext` provides context information about transitions.
///
/// It is especially useful for deep linking as XCoordinator can internally gather information about
/// the presentables being pushed onto the view hierarchy.
///
public protocol TransitionContext {
    
    /// The presentables being shown to the user by the transition.
    var presentables: [Presentable] { get }
    
    ///
    /// The transition animation directly used in the transition, if applicable.
    ///
    /// - Note:
    ///     Make sure to not return `nil`, if you want to use `BaseCoordinator.registerInteractiveTransition`
    ///     to realize an interactive transition.
    ///
    var animation: TransitionAnimation? { get }
}
