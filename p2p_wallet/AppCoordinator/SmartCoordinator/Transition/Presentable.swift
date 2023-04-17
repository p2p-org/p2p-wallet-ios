///
/// Presentable represents all objects that can be presented (i.e. shown) to the user.
///
/// Therefore, it is useful for view controllers, coordinators and views.
/// Presentable is often used for transitions to allow for view controllers and coordinators to be transitioned to.
///
public protocol Presentable {
    
    ///
    /// The viewController of the Presentable.
    ///
    /// In the case of a `UIViewController`, it returns itself.
    /// A coordinator returns its rootViewController.
    ///
    var viewController: UIViewController! { get }
}
