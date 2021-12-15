//
// Created by Giang Long Tran on 13.12.21.
//

import Foundation
import BEPureLayout
import RxCocoa
import RxSwift

// MARK: Navigation Model
enum NavigationType {
    case push(_ vc: UIViewController)
    case modal(_ vc: UIViewController)
    case pop
    case none
}

protocol BESceneNavigationModel: AnyObject {
    var navigationDriver: Driver<NavigationType> { get }
    func listenNavigation(vc: UIViewController) -> Disposable
}

extension BESceneNavigationModel {
    func listenNavigation(vc: UIViewController) -> Disposable {
        navigationDriver.drive(onNext: { [weak vc] event in
            guard let vc = vc else { return }
            switch event {
            case .push(let newVc):
                vc.show(newVc, sender: nil)
            case .modal(let newVc):
                vc.present(newVc, animated: true)
            case .pop:
                vc.close()
            default:
                return
            }
        })
    }
}

@propertyWrapper
struct BENavigationBinding<Value> {
    private var value: Value?
    
    @available(*, unavailable, message: "This property wrapper can only be applied to classes")
    var wrappedValue: Value {
        get { fatalError() }
        // swiftlint:disable unused_setter_value
        set { fatalError() }
    }
    
    public static subscript<T: BEScene>(
        _enclosingInstance viewController: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    ) -> Value {
        get {
            viewController[keyPath: storageKeyPath].value!
        }
        set {
            if let newValue = newValue as? BESceneNavigationModel {
                newValue.listenNavigation(vc: viewController).disposed(by: viewController.disposeBag)
            }
            viewController[keyPath: storageKeyPath].value = newValue
        }
    }
}
