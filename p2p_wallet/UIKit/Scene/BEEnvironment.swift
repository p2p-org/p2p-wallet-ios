//
// Created by Giang Long Tran on 14.12.21.
//

import Foundation

class BEEnvironmentContainer: BECompositionView {
    let values: [BESceneModel]
    let child: UIView
    
    init(value: BESceneModel, @BEViewBuilder child: Builder) {
        self.values = [value]
        self.child = child().build()
        super.init()
    }
    
    func resolve<SceneModel>(_ _type: SceneModel.Type) -> BESceneModel? {
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
    func withEnvironment(_ value: BESceneModel) -> UIView {
        BEEnvironmentContainer(value: value) { self }
    }
}

@propertyWrapper
struct EnvironmentVariable<Value: BESceneModel> {
    private var value: Value?
    
    var wrappedValue: Value {
        get { value! }
        set { value = newValue }
    }
    
    static subscript<OuterSelf: UIView>(
        instanceSelf view: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> Value {
        get {
            if view[keyPath: storageKeyPath].value == nil {
                var currentView: UIView? = view
                while (currentView != nil) {
                    if let currentView = currentView as? BEEnvironmentContainer {
                        if let result = currentView.resolve(Value.self) {
                            view[keyPath: storageKeyPath].value = result as! Value
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
