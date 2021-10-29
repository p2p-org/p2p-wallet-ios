# P2P Wallet
P2P Wallet on Solana blockchain

## Features

- [x] Create new wallet
- [x] Restore existing wallet using seed phrases
- [x] Decentralized identification (name service)
- [x] Send SOL, SPL tokens and renBTC via name or address
- [x] Receive SOL, SPL tokens and renBTC
- [x] Swap SOL and SPL tokens (powered by Orca)
- [ ] Buy tokens (moonpay)

## Requirements

- iOS 13.0+
- Xcode 12

## Installation

#### Add Config.xconfig (ask team manager)
```
RPCPOOL_API_KEY = <your_key>

TRANSAK_STAGING_API_KEY = <your_key>
TRANSAK_PRODUCTION_API_KEY = <your_key>
TRANSAK_HOST_URL = <your_key>

// Mark: - Moonpay
MOONPAY_STAGING_API_KEY = <your_key>
MOONPAY_PRODUCTION_API_KEY = <your_key>

// MARK: - CryptoCompareAPI
CRYPTO_COMPARE_API_KEY = <your_key>

// MARK: - Amplitude
AMPLITUDE_API_KEY = <your_key>

// MARK: - FeeRelayer
FEE_RELAYER_ENDPOINT = <your_key>
```

#### Install dependencies (cocoapods)
- Clone project and retrieve all submodules
```zsh
git clone git@github.com:p2p-org/p2p-wallet-ios.git
git submodule update --init --recursive
```
- Override `githook` directory:
```zsh
git config core.hooksPath .githooks
```
- Run `swiftgen` for the first time
```zsh
Pods/swiftgen/bin/swiftgen config run --config swiftgen.yml
```
- Run `pod install`

## Contribute

We would love you for the contribution to **P2P Wallet**, check the ``LICENSE`` file for more info.
