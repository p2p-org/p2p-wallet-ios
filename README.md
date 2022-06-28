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
FEE_RELAYER_ENDPOINT = fee-relayer.solana.p2p.org
TEST_ACCOUNT_SEED_PHRASE = account-test-seed-phrase-separated-by-hyphens
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

## Code style

- Space indent: 4
- NSAttributedString 
Example:
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
Result
<img width="113" alt="image" src="https://user-images.githubusercontent.com/6975538/160050828-f1231cbb-070b-4dba-bb83-c4a284cf3d2d.png">


## UI Templates

- Copy template `BEScene2.xctemplate` that is located under `Templates` folder to  `~/Library/Developer/Xcode/Templates/`
```zsh
mkdir -p ~/Library/Developer/Xcode/Templates/BEScene2.xctemplate
cp -R Templates/BEScene2.xctemplate ~/Library/Developer/Xcode/Templates
```

## Dependency Injection

- Resolver

## Contribute

We would love you for the contribution to **P2P Wallet**, check the ``LICENSE`` file for more info.


## Feature Flags

### Add feature flag steps

- Add feature flag to Firebase Remote Config
- Add feature flag with the same title to `public extension Feature` struct

```
public extension Feature {
    static let sslPinning = Feature(rawValue: "ssl_pinning")
    static let sslPinning = Feature(rawValue: "new_feature_flag")
}
```

### Feature flag using example

```
if available(.sslPinning) {
    showSslPinningScreen(
        input: input,
        state: status.creditState
    )
} else {
    showAppStatus(
        input: input,
        status: status
    )
}
```
