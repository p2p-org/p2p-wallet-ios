//
// Created by Giang Long Tran on 14.12.21.
//

import Foundation

class BEEnvironmentContainer: BECompositionView {
    let values: [Any]
    let child: UIView
    
    init(value: Any, @BEViewBuilder child: Builder) {
        self.values = [value]
        self.child = child().build()
        super.init()
    }
    
    func resolve<AnyObject>(_ _type: AnyObject.Type) -> Any? {
        for value in values {
            if type(of: value) == _type { return value }
        }
        return nil
    }
    
    override func build() -> UIView {
        child
    }
}

extension UIView {
    func withEnvironment(_ value: AnyObject) -> UIView {
        BEEnvironmentContainer(value: value) { self }
    }
}

@propertyWrapper
struct EnvironmentVariable<Value> {
    private var value: Value?
    
    @available(*, unavailable, message: "This property wrapper can only be applied to classes")
    var wrappedValue: Value {
        get { fatalError() }
        // swiftlint:disable unused_setter_value
        set { fatalError() }
    }
    
    static subscript<OuterSelf: UIView>(
        _enclosingInstance view: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> Value {
        get {
            if view[keyPath: storageKeyPath].value == nil {
                var currentView: UIView? = view
                while currentView != nil {
                    if let currentView = currentView as? BEEnvironmentContainer {
                        if let result = currentView.resolve(Value.self) {
                            view[keyPath: storageKeyPath].value = result as? Value
                        }
                    }
                    currentView = currentView!.superview
                }
            }
            
            return view[keyPath: storageKeyPath].value!
        }
        set {
            view[keyPath: storageKeyPath].value = newValue
        }
    }
}
