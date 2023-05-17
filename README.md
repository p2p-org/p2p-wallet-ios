# Key App

Key App wallet on Solana blockchain

## Features

- [x] Create new wallet
- [x] Restore existing wallet using seed phrases
- [x] Decentralized identification (name service)
- [x] Send SOL, SPL tokens and renBTC via name or address
- [x] Receive SOL, SPL tokens and renBTC
- [x] Swap SOL and SPL tokens (powered by Orca)
- [x] Buy tokens (moonpay)

## Requirements

- iOS 14.0+
- Xcode 14.3
- SwiftFormat

## Installation

- Clone project and move to folder
```shell
git clone git@github.com:p2p-org/p2p-wallet-ios.git && cd p2p-wallet-ios
```
- Get submodules
```shell
git submodule update --init --recursive
```
- Set git hooks (Optional)
```shell
git config core.hooksPath .githooks
chmod -R +x .githooks
```
- Add `Config.xcconfig` to `p2p-wallet-ios/p2p-wallet` contains following content
```
// MARK: - Transak
TRANSAK_STAGING_API_KEY = fake_api_key
TRANSAK_PRODUCTION_API_KEY = fake_api_key
TRANSAK_HOST_URL = p2p.org

// Mark: - Moonpay
MOONPAY_STAGING_API_KEY = fake_api_key
MOONPAY_PRODUCTION_API_KEY = fake_api_key

// MARK: - Amplitude
AMPLITUDE_API_KEY = fake_api_key

// MARK: - FeeRelayer
FEE_RELAYER_STAGING_ENDPOINT = test-solana-fee-relayer.wallet.p2p.org
FEE_RELAYER_ENDPOINT = fee-relayer.solana.p2p.org
TEST_ACCOUNT_SEED_PHRASE = account-test-seed-phrase-separated-by-hyphens

// MARK: - NameService
NAME_SERVICE_ENDPOINT = name_service.org
```
- Run install.sh
```shell
chmod u+x Scripts/install.sh && Scripts/install.sh
```

- Select target `p2p_wallet` (if `Detect Unused Code` is selected by default after xcodegen)

## Localization

- Download [LocalizationHelper app](https://github.com/bigearsenal/XCodeLocalizationHelper/raw/main/release/LocalizationHelper.zip)
- Copy `LocalizationHelper` to `Applications`
- After xcodegen, the LocalizationHelper stopped working, so here is the solution:
1. Click "Open..."
2. Choose `Tuist project` instead of `Default project`
   
<img width="686" alt="image" src="https://user-images.githubusercontent.com/6975538/172043618-f945c283-ad36-4030-ab3f-4cfd6a2a3660.png">

3. Choose project root folder (p2p-wallet-ios)
4. Resouces folder must be p2p-wallet-ios/p2p_wallet

<img width="673" alt="image" src="https://user-images.githubusercontent.com/6975538/172043669-84883ac3-a35f-4ce4-b576-3a25564bed30.png">

5. Click open project.

<img width="673" alt="image" src="https://user-images.githubusercontent.com/6975538/172043669-84883ac3-a35f-4ce4-b576-3a25564bed30.png">

6. Change "Run automation" to "Pods/swiftgen/bin/swiftgen config run --config swiftgen.yml"

<img width="682" alt="image" src="https://user-images.githubusercontent.com/6975538/172043833-ebb5b808-3b11-4e2a-a46e-727503b61e03.png">

## CI/CD

- `Swiftgen` for automatically generating strings, assets.
- `Swiftlint`, SwiftFormat for linting, automatically formating code
- `Periphery` for detecting dead code (use Detect Unused Code target and run)
- `CircleCI` or `GithubAction`: implementing...

### Fastlane config (optional)
Add `.env` file contains following content (ask teamate):
```
DEVELOPER_APP_IDENTIFIER=""
APP_STORE_CONNECT_TEAM_ID=""
DEVELOPER_PORTAL_TEAM_ID=""
DEVELOPER_APP_ID=""
PROVISIONING_PROFILE_SPECIFIER_ADHOC=""
PROVISIONING_PROFILE_SPECIFIER_APPSTORE=""
APPLE_ISSUER_ID=""
PROVISIONING_REPO=""

FIREBASE_APP_ID=""
FIREBASE_CLI_TOKEN=""

BROWSERSTACK_USERNAME=""
BROWSERSTACK_ACCESS_KEY=""

FASTLANE_APPLE_ID=""
TEMP_KEYCHAIN_USER=""
TEMP_KEYCHAIN_PASSWORD=""
APPLE_KEY_ID=""
APPLE_KEY_CONTENT=""
GIT_AUTHORIZATION=""
MATCH_PASSWORD=""
IS_CI=false

XCCONFIG_URL=""

```

## UI Templates

- Copy template `MVVM-C.xctemplate` that is located under `Templates` folder to  `~/Library/Developer/Xcode/Templates/`
```zsh
mkdir -p ~/Library/Developer/Xcode/Templates/MVVM-C.xctemplate
cp -R Templates/MVVM-C.xctemplate ~/Library/Developer/Xcode/Templates
```

## Dependency Injection

- Resolver

## Contribute

We would love you for the contribution to **Key App**, check the ``LICENSE`` file for more info.


## Feature Flags

### Add feature flag steps

- Add feature flag to Firebase Remote Config with style: `settingsFeature`
- Add feature flag with the same title to `public extension Feature` struct

```
public extension Feature {
    static let settingsFeature = Feature(rawValue: "settingsFeature")
}
```

- Add feature flag to DebugMenuViewModel

```
extension DebugMenuViewModel {
    enum Menu: Int, CaseIterable {
        case newSettings

        var title: String {
            switch self {
            case .newSettings:
                return "New Settings"
            }
        }

        var feature: Feature {
            switch self {
            case .newSettings:
                return .settingsFeature
            }
        }
    }
}
```

### Feature flag using example

```
if available(.settingsFeature) {
    showNewSettingsScreen(
        input: input,
        state: status.creditState
    )
} else {
    showOldSettingsScreen(
        input: input,
        status: status
    )
}
```

## Code style

The basis of the style of writing code is the configured Swiftlint in the project. The specific practices we follow are listed below.

### Calls from View to ViewModel
Name ViewModel functions as action from View:

🟢
```
.onTapGesture {
    viewModel.buttonTapped()
}
```

🔴
```
.onTapGesture {
    viewModel.sendToken()
}
```


### Protocols
Interfaces used for abstractions are named without prefixes and postfixes:

🟢
```
protocol IBuyService {}
```

🔴
```
protocol BuyServiceProtocol {}
```


For implementation we use natural name, for mocks append `Mock` or other key words in the ending:

🟢
```
final class BuyService: BuyService {}
final class BuyServiceMock: BuyService {}
```

🔴
```
final class BuyServiceImpl: BuyService {}
final class BuyMockService: BuyService {}
```


If it is known in advance that only classes will conform to the protocol, you need to add the keyword AnyObject:

🟢
```
protocol SomeProtocol: AnyObject {}
```

🔴
```
protocol SomeProtocol {}
```


### Class structure
We try to avoid inheritance. For all classes from which inheritance is not planned, the final keyword must be explicitly specified. This speeds up the dispatching of calls in runtime and makes life easier for the compiler.:

```
final class BuyView: UIView {}
```


Dependencies and properties are always written at the top of the class, indicated by a comment without indentation after:

🟢
```
final class SomeClass {

    // Dependencies
    private let buyService: BuyService
    private let sellService: SellService

    // Private properties
    private var amount: Double?
}
```

🔴
```
final class SomeClass {

    // Dependencies

    private let buyService: BuyService
    private let sellService: SellService

    // Private properties

    private var amount: Double?
}
```


All other elements are indicated with // MARK: - indented after:

🟢
```
final class SomeClass {

    // MARK: - Init

    public init() {...}

    // MARK: - BuyService

    func buyCrypto(_ crypto: Crypto) {...}
}
```

🔴
```
final class SomeClass {

    // MARK: - Init
    public init() {...}

    // MARK: - BuyService
    func buyCrypto(_ crypto: Crypto) {...}
}
```


If a large number of private functions are typed, then you should not dump them all in one pile, you need to break them into logically connected blocks.

🟢 Division within the class:
```
final class SomeClass {

    // MARK: - Listeners

    private func addListeners() {...}
    private func removeListeners() {...}
    private func removeListener(_ listener: Listener) {...}

    // MARK: - Actions

    @objc private func didTapClose() {...}
}
```


🟢 Takeaway in extensions:
```
final class SomeClass {
    ...
}

// MARK: - Listeners

extension SomeClass {
    private func addListeners() {...}
    private func removeListeners() {...}
    private func removeListener(_ listener: Listener) {...}
}

// MARK: - Actions

extension SomeClass {
   @objc private func didTapClose() {...}
}
```

🔴
```
final class SomeClass {

    // MARK: - Private

    func addListeners() {...}
    @objc func didTapClose() {...}
    func removeListeners() {...}
    func removeListener(_ listener: Listener) {...}
}
```


There should be no line break before the closing brackets:

🟢
```
struct SomeStruct {
    func listen() {
        ...
    }
}
```

🔴
```
struct SomeStruct {
    func listen() {
        ...
    }

}
```


### Switch statement
For enum we don't use default in switch. When changing the enum during assembly, all the places where it is used will be immediately visible:

🟢
```
enum SomeEnum {
    case one
    case two
    case three
    case four
}

switch enum {
    case .one: // do something
    case .two: // do something
    case .three, .four: break
}
```

🔴
```
enum SomeEnum {
    case one
    case two
    case three
    case four
}

switch enum {
    case .one: // do something
    case .two: // do something
    default: break
}
```


### Redundant code
In the .map functions .filter .reduce etc. omit the parentheses:

🟢
```
dict.map { $0 }
dict.filter { $0 % 2 == 0 }
```

🔴
```
dict.map({ $0 })
dict.filter({ $0 % 2 == 0 })
```


For the returned parameters in closure, we omit the parentheses:

🟢
```
let handler: SomeHandler = { [weak self] action, indexPath in
    self?.didTrigger(action, onItemAt: indexPath)
}
```

🔴
```
let handler: SomeHandler = { [weak self] (action, indexPath) in
    self?.didTrigger(action, onItemAt: indexPath)
}
```


### TODO comments
In TODO, we specify the version in which the fix is planned, your nickname and a link to the task in JIRA.

```
// TODO: 2.7 vasya.pupkin later take out the logic in BuyService https://jira..../task
```


### Constants
### Local constants
All constants should be at the very top of the file, right after the imports.
If the constants are of the same type, combine them into an extension:

```
private extension CGFloat {
    static let horizontalPadding: CGFloat = 5
    static let verticalPadding: CGFloat = 5
}

// Using
SomeView {...}
   .padding(.horizontal, .horizontalPadding)
   .padding(.vertical, .verticalPadding)
```


If constants of different types are combined into enum:

```
private enum Constants {
    static let boxCornerRadius: CGFloat = 5
    static let boxInitSize = CGSize(width: 60, height: 40)
    static let boxSize = CGSize(width: 60, height: 40)
    static let boxInitCornerRadius: CGFloat = 5
}
```


### Naming
We use direct naming, not the reverse.

🟢
```
let limitsController: UIViewController
```

🔴
```
let controllerLimits: UIViewController
```


We are getting old to avoid duplication of information in function names.

🟢
```
func didSelectCell(at indexPath: IndexPath)
```

🔴
```
func didSelectCellAtIndexPath(_ indexPath: IndexPath)
```


### Recommendations
If the protocol requires an implementation and does not contain set properties, then it is better to use extension:

```
protocol BuyService {
  func buy()
}
```

🟢
```
final class BuyServiceImpl {
    ...
}

// MARK: - BuyService

extension BuyServiceImpl: BuyService {

   func buy() {}
}
```

🔴
```
final class BuyServiceImpl: BuyService {
    ...

    // MARK: - BuyService

    func buy() {}
}
```
