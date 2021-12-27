#  Using Resolver with ViewModels

Resolver is an ultralight Dependency Injection / Service Locator framework for Swift 5.x on iOS, which is understood simply as a tool that **gives objects the things it needs to do its job**

This project use `MVVM` as the architecture pattern, `Resolver` as the `Service Locator`.

## What we need from Resolver

We want the most simple way to inject `ViewModel`s to its `ViewController` and `RootView`. So, most of the time, we use [Annotation Injection](https://github.com/hmlongco/Resolver/blob/master/Documentation/Injection.md#annotation) to get the job done. Like the pattern below:

```swift
// register
register { MyScene.ViewModel() }
    .implements(MySceneViewModelType.self)
    .scope(.shared)

// MyScene.swift
enum MyScene {
    ...
}

// MyScene.ViewModel.swift
protocol MySceneViewModelType {
    ...
}

extension MyScene {
    final class ViewModel: MySceneViewModelType {
        @Injected private var serviceA: ServiceAType
        @Injected private var serviceB: ServiceBType
        ...
    }
}

// MyScene.ViewController.swift
extension MyScene {
    final class ViewController: UIViewController {
        @Injected private var viewModel: MySceneViewModelType
        ...
    }
}

// MyScene.RootView.swift
extension MyScene {
    final class RootView: UIView {
        @Injected private var viewModel: MySceneViewModelType
    }
}
```
This pattern is lightweight and easy picky. But sometimes, we will find it hard to addapt because of some limitation of `Annotation Injection`, see the section below.

## What prevented us from using Annotation Injection?

### Some services were not registered using Resolver

- Problem: some services were not registered using `Resolver.registerAllServices()` method, so we had to inject it using `Constructor Injection`, and it breaks the simple pattern in the previous section. This make code more repeatable and unconsistent, because in some Scenes, we use `Annotation Injection`, and in another, we can't:

```swift
// MainContainer.swift
func makeMySceneViewController() -> MyScene.ViewController {
    let vm = MyScene.ViewModel(walletsRepository: walletsViewModel, pricesService: pricesService)
    return .init(viewModel: vm, scenesFactory: self)
}

// MyScene.ViewModel.swift
protocol MySceneViewModelType {
    ...
}

extension MyScene {
    final class ViewModel: MySceneViewModelType {
        private var walletsRepository: WalletsRepository
        private var pricesService: PricesServiceType
        
        init(walletsRepository: WalletsRepository, pricesService: PricesServiceType) {
            ...
        }
    }
}

// MyScene.ViewController.swift
extension MyScene {
    final class ViewController: UIViewController {
        private let viewModel: MySceneViewModelType // we could not use Annotation Injection here
        init(viewModel: MySceneViewModelType, sceneFactory: MySceneFactory) {
            ...
        }
    }
}

// MyScene.RootView.swift
extension MyScene {
    final class RootView: UIView {
        private let viewModel: MySceneViewModelType // The same for RootView: We could not use Annotation Injection here
        init(viewModel: MySceneViewModelType, sceneFactory: MySceneFactory) {
            ...
        }
    }
}
```

- Resolution: All services are right now registered with `Resolver` with suitable scope:

```swift
// MARK: - PricesService
register { PricesService() }
    .implements(PricesServiceType.self)
    .scope(.session) // PAY ATTENTION TO SCOPE

// MARK: - WalletsViewModel
register { WalletsViewModel() }
    .implements(WalletsRepository.self)
    .scope(.session) // PAY ATTENTION TO SCOPE

```

Scope `session` has been added by [Andrew Vasiliev](https://github.com/OldCrab) to handle services that live from its creation time to `logout` function (the time when `ResolverScope.session.reset()` is being called). So when you need to create new Service of this type, use scope `.session`.

By using right scope, we can get rid of `MainContainer.swift` because we can now control the lifecycle of Service using `Resolver`'s scope directly.

- Result: The cost of creating and injecting MyScene.ViewModel has been reduced by using `Annotation Injection`

```swift
// MyScene.ViewModel.swift
extension MyScene {
    final class ViewModel: MySceneViewModelType {
        @Injected private var walletsRepository: WalletsRepository
        @Injected private var pricesService: PricesServiceType
        ...
    }
}

// MyScene.ViewController.swift
extension MyScene {
    final class ViewController: UIViewController {
        @Injected private var viewModel: MySceneViewModelType
        ...
    }
}

// MyScene.RootView.swift
extension MyScene {
    final class RootView: UIView {
        @Injected private var viewModel: MySceneViewModelType
    }
}
```

### Sometimes we need to "inject" data (not service) to the ViewModel, but in facts, data **isn't supposed to be injected**
- Problem: [(Source)](https://github.com/hmlongco/Resolver/blob/609908e0b67911ebf7386609552a48d4ec07958e/Documentation/Arguments.md#inject-services-not-data)
> One of the things that many people miss is that dependency injection’s concern lies in constructing the service graph.
> 
> To put that into English, it means the dependency-injection system creates and connects the services and the components that manage and process the application’s data. Data is information that's created and manipulated at runtime and passed from object to dependent object using an object’s methods and functions.
> 
> Data is never injected.
> 
> If an object requires data or values created or manipulated during runtime I'd do something like the following....

```swift
class DummyViewModel {
    func load(id: Int, editing: Bool) { }
}

class DummyViewController: UIViewController {

    var id: Int = 0
    var editing: Bool = false

    @Injected var viewModel: DummyViewModel

    override func viewDidLoad() {
        super.viewDidLoad()
        someSetup()
        viewModel.load(id: id, editing: editing)
    }
}
```
> Our DummyViewModel service is automatically injected when DummyViewController is instantiated, but it's load method is called with the needed parameters during viewDidLoad.
> 
> Note that type information is now preserved. Argument order is maintained. And explicit unwrapping of arguments is not required.
> 
> Plus I now have the added benefit of being able to control exactly when and where in the code I call my configuration function. Consequently I can ensure that any initialization needed by my view controller is performed prior to doing so.

In our project, there is some places that data was "injected" using `Constructor Injection` in `ViewModel`. Example:

```swift
extension ChooseWallet {
    class ViewModel: BaseVM {
        // MARK: - Dependencies
        private(set) var selectedWallet: Wallet?
        private(set) var showOtherWallets: Bool
        ...
        
        init(
            selectedWallet: Wallet?,
            showOtherWallets: Bool
        ) {
            self.selectedWallet = selectedWallet
            self.showOtherWallets = showOtherWallets
            super.init()
            ...
        }
        ...
    }
}
```
It prevented us from resolving ViewModel using `Annotation Injection`, because `ViewModel` requires parameters to be initialized

- Resolution: **Avoid using init() with parameters in ViewModel**, use `ViewController` as `Scene`'s coordinator, and set up all needed data for `ViewModel` in `ViewController`'s initializer.

```swift

// ChooseWallet.ViewModel.swift
extension ChooseWallet {
    class ViewModel {
        // MARK: - Dependencies
        private(set) var selectedWallet: Wallet?
        private(set) var showOtherWallets: Bool! // CHANGE TYPE TO IMPLICITLY UNWRAPPED OPTIONAL TO SET IT LATER
        ...
        
        func set( // DON'T USE INIT, USE SET/LOAD FUNCTION TO "INJECT" DATA
            selectedWallet: Wallet?,
            showOtherWallets: Bool
        ) {
            self.selectedWallet = selectedWallet
            self.showOtherWallets = showOtherWallets
            ...
        }
        ...
    }
}

// ChooseWallet.ViewController.swift
extension ChooseWallet {
    class ViewController {
        @Injected private var viewModel: ChooseWalletViewModelType // ANNOTATION INJECTION IS AVAILABLE, BECAUSE THERE IS NO PARAMETERS IN INIT() FUNCTION
        
        init(
            selectedWallet: Wallet?,
            showOtherWallets: Bool
        ) {
            super.init()
            viewModel.set(selectedWallet: selectedWallet, showOtherWallets: showOtherWallets) // SET DATA HERE
        }
    }
}

// In another scene, sceneFactory is not needed anymore, we can USE VIEWCONTROLLER DIRECTLY AS A COORDINATOR for ChooseWallet scene
let vc = ChooseWallet.ViewController(selectedWallet: wallet, showOtherWallets )
show(vc, sender: nil)
```

## What needs to be done before merging this PR:
[x] Fully detecting memory leaks (memory leaks prevent makes strange behaviour when using scope .shared on ViewModel)

[ ] Fully testing application, especially some services like RenVM.LockAndMint.Service and RenVM.BurnAndRelease.Service, and fix possible broken functions.
