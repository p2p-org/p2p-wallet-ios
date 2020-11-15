# p2p-wallet-ios

![](https://cdn.discordapp.com/attachments/737610668726812763/777332771138961488/wallets_ios2x.png)

## About

An Open ios client for Solana-based Wallet. 

Version "0.1a Wormhole Hackathon" 

Built on top of Solana, ProjectSerum, Bonfida API

## Features
- [x] Create/Access Wallet with seed. Your private keys are only stored on your current computer or device.
- [x] Displaying balances of SOL token and Wrapped tokens
- [x] Displaying the value of assets in dollars.
- [x] HD (BIP32,BIP39) support
- [x] UI: darkmode, localization support for English, Russian, France and Vietnamese languages
- [ ] Create Wrapped tokens addresses
- [ ] Send and receive SOL token and Wrapped tokens
- [ ] Transaction history
- [ ] Transaction details
- [ ] QR code generation
- [ ] One-tap access to swap assets
- [ ] Improving security
- [ ] Wallet Connect integration
- [ ] Send/Receive Wrapped tokens to/from Ethereum Blockchain
- [ ] DeFi support

## Build and Runtime Requirements
+ Xcode 10.0 or later
+ iOS 12.0 or later
+ Cocoapods

## Prerequisite
+ RxSwift, RxCocoa, MVVM
+ PureLayout, layout WITHOUT using InterfaceBuilder (Storyboard, Xib)

## Configuring the Project

1) Clone the project and its dependencies
```zsh
$ git clone git@github.com:p2p-org/p2p-wallet-ios.git p2p_wallet
$ cd p2p_wallet && pod install
```
2) Run project

## Application Architecture

- UI/UX: Using [BEPureLayout](https://github.com/bigearsenal/bepurelayout), which depends on PureLayout, which does NOT use any InterfaceBuilder (Storyboard, Xib)...
    - Every new `UIViewController` must inherit from `BaseVC` or `BaseVStackVC` (a predefined `UIViewController` that have ready-to-use vertical `UIStackView` that can add as many arrangedSubviews as needed and flexibly grows height inside a `ContentHuggingScrollView` (inherited from `UIScrollView`)
    - `UIViewController` that contains a list can inherit from predefined `UICollectionView`-based `CollectionView<ItemType: Hasable, CellType>`, see the implementation of [WalletVC](https://github.com/p2p-org/p2p-wallet-ios/blob/main/p2p_wallet/Scenes/WalletVC/WalletVC.swift) for more details.
- MVVM: The MVVM (Model-View-ViewModel) pattern helps to completely separate the business and presentation logic from the UI, and the business logic and UI can be clearly separated for easier testing and easier maintenance.
    - Any `ViewModel` must inherit from `BaseVM<ItemType>`, `ListViewModel` must inherit from `ListViewModel<Element>`

## Contributing

The best way to submit feedback and report bugs is to open a GitHub issue. Please be sure to include your operating system, device, version number, and steps to reproduce reported bugs.
