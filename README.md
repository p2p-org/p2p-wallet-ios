# P2P Wallet

P2P Wallet on Solana blockchain

## Features

- [x] Create new wallet
- [x] Restore existing wallet using seed phrases
- [x] Decentralized identification (name service)
- [x] Send SOL, SPL tokens and renBTC via name or address
- [x] Receive SOL, SPL tokens and renBTC
- [x] Swap SOL and SPL tokens (powered by Orca)
- [x] Buy tokens (moonpay)

## Requirements

- iOS 13.0+
- Xcode 12
- SwiftFormat

## Installation

- Clone project and retrieve all submodules
```zsh
git clone git@github.com:p2p-org/p2p-wallet-ios.git
cd p2p-wallet-ios
git submodule update --init --recursive
```
- Override `githook` directory:
```zsh
git config core.hooksPath .githooks
chmod -R +x .githooks
```
- Run `pod install`
- Run `swiftgen` for the first time
```zsh
Pods/swiftgen/bin/swiftgen config run --config swiftgen.yml
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
FEE_RELAYER_ENDPOINT = fee-relayer.solana.p2p.org
TEST_ACCOUNT_SEED_PHRASE = account-test-seed-phrase-separated-by-hyphens
```

## Localization

- Download [LocalizationHelper app](https://github.com/bigearsenal/XCodeLocalizationHelper/raw/main/release/LocalizationHelper.zip)
- Copy `LocalizationHelper` to `Applications`
- Open `.xcproj` file from `LocalizationHelper`
- Add key and setup automation

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

## Code style

- Space indent: 4
- NSAttributedString
```swift
label.attributedText = 
   NSMutableAttributedString()
      .text(
          "0.00203928 SOL",
          size: 15,
          color: .textBlack
      )
      .text(
          " (~$0.93)",
          size: 15,
          color: .textSecondary
      )
```
Result: <img width="113" alt="image" src="https://user-images.githubusercontent.com/6975538/160050828-f1231cbb-070b-4dba-bb83-c4a284cf3d2d.png">

- MVVM RxSwift
```swift
// MARK: - ViewModel
final class TransactionViewModel {
    let input = Input()
    let output: Output

    init(transaction: SolanaSDK.ParsedTransaction, clipboardManager: ClipboardManagerType) {
        let fromView = input.view
        let showWebView = fromView.transactionDetailClicked
            .mapTo("https://explorer.solana.com/tx/\(transaction.signature ?? "")")
        let model = fromView.viewDidLoad.mapTo(transaction.formatted())
        let copyTransactionId = fromView.transactionIdClicked
            .mapTo(transaction.signature ?? "")
            .do(onNext: { clipboardManager.copyToClipboard($0) })
            .mapToVoid()

        let view = Output.View(model: model.asDriver(), copied: copyTransactionId.asDriver())
        let coord = Output.Coord(showWebView: showWebView.asDriver())
        output = Output(view: view, coord: coord)
    }
}

extension TransactionViewModel: ViewModel {
    struct Input: ViewModelIO {
        let view = View()
        let coord = Coord()

        struct View {
            let viewDidLoad = PublishRelay<Void>()
            let transactionIdClicked = PublishRelay<Void>()
        }

        class Coord {}
    }

    struct Output: ViewModelIO {
        typealias Model = History.TransactionView.Model

        let view: View
        let coord: Coord

        struct View {
            var model: Driver<Model>
            var copied: Driver<Void>

            init(
                model: Driver<Model>,
                copied: Driver<Void>
            ) {
                self.model = model
                self.copied = copied
            }
        }

        class Coord {
            var showWebView: Driver<String>

            init(showWebView: Driver<String>) {
                self.showWebView = showWebView
            }
        }
    }
}
```
```swift
// MARK: - ViewController
final class TransactionViewController: WLModalViewController {
    @Injected private var notificationService: NotificationsServiceType

    private lazy var customView = TransactionView()

    private let viewModel: TransactionViewModel

    init(viewModel: TransactionViewModel) {
        self.viewModel = viewModel
    }

    override func build() -> UIView { customView }

    override func bind() {
        super.bind()

        let (input, output) = viewModel.viewIO

        rx.viewWillAppear
            .take(1)
            .mapTo(())
            .bind(to: input.viewDidLoad)
            .disposed(by: disposeBag)
        customView.rx
            .transactionIdClicked
            .bind(to: input.transactionIdClicked)
            .disposed(by: disposeBag)

        output.model
            .drive(customView.rx.model)
            .disposed(by: disposeBag)
        output.copied
            .drive(onNext: { [weak self] in
                self?.notificationService.showInAppNotification(.done(L10n.copiedToClipboard))
            })
            .disposed(by: disposeBag)

        // TODO: - Move to coordinator later

        let (_, coordinatorOutput) = viewModel.coordIO

        coordinatorOutput.showWebView
            .drive(onNext: { [unowned self] url in
                showWebsite(url: url)
            })
            .disposed(by: disposeBag)
    }
}
```
```swift
// MARK: - View
final class TransactionView: BECompositionView {
    override func build() -> UIView {
        UILabel(text: "Hello World")
    }
}
```

## UI Templates

- Copy template `BEScene.xctemplate` that is located under `Templates` folder to  `~/Library/Developer/Xcode/Templates/File\ Templates/Templates/BEScene.xctemplate`
```zsh
mkdir -p ~/Library/Developer/Xcode/Templates/File\ Templates/BEScene.xctemplate
cp -R Templates/BEScene.xctemplate ~/Library/Developer/Xcode/Templates/File\ Templates/BEScene.xctemplate
```

## Dependency Injection

- Resolver

## Contribute

We would love you for the contribution to **P2P Wallet**, check the ``LICENSE`` file for more info.
