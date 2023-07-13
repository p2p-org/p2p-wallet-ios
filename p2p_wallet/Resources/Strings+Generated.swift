// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// %@\nPlease log in with the correct %@ account.
  internal static func pleaseLogInWithTheCorrectAccount(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "%@\nPlease log in with the correct %@ account.", String(describing: p1), String(describing: p2))
  }
  /// %@ Account Creation
  internal static func accountCreation(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ Account Creation", String(describing: p1))
  }
  /// %@ Closed
  internal static func closed(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ Closed", String(describing: p1))
  }
  /// %@ Created
  internal static func created(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ Created", String(describing: p1))
  }
  /// %@ found
  internal static func found(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ found", String(describing: p1))
  }
  /// %@ is available
  internal static func isAvailable(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ is available", String(describing: p1))
  }
  /// %@ is successfully sent
  internal static func isSuccessfullySent(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ is successfully sent", String(describing: p1))
  }
  /// %@ is successfully swapped to %@
  internal static func isSuccessfullySwappedTo(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "%@ is successfully swapped to %@", String(describing: p1), String(describing: p2))
  }
  /// %@ is the minimum amount to receive from the Ethereum Network
  internal static func isTheMinimumAmountToReceiveFromTheEthereumNetwork(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ is the minimum amount to receive from the Ethereum Network", String(describing: p1))
  }
  /// **%@** is the remaining time to safely send the assets.
  internal static func isTheRemainingTimeToSafelySendTheAssets(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ is the remaining time to safely send the assets.", String(describing: p1))
  }
  /// %@ is unavailable
  internal static func isUnavailable(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ is unavailable", String(describing: p1))
  }
  /// %@ isn’t available
  internal static func isnTAvailable(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ isn’t available", String(describing: p1))
  }
  /// %@ Liquidity fee %@
  internal static func liquidityFee(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "%@ Liquidity fee %@", String(describing: p1), String(describing: p2))
  }
  /// %@ mint address
  internal static func mintAddress(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ mint address", String(describing: p1))
  }
  /// %@ Network
  internal static func network(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ Network", String(describing: p1))
  }
  /// %@ purchase cost
  internal static func purchaseCost(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ purchase cost", String(describing: p1))
  }
  /// %@ signature
  internal static func signature(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ signature", String(describing: p1))
  }
  /// %@ successfully sent
  internal static func successfullySent(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ successfully sent", String(describing: p1))
  }
  /// %@ to %@
  internal static func to(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "%@ to %@", String(describing: p1), String(describing: p2))
  }
  /// %@ transactions
  internal static func transactions(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ transactions", String(describing: p1))
  }
  /// %@ was sent successfully
  internal static func wasSentSuccessfully(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@ was sent successfully", String(describing: p1))
  }
  /// %@ → %@ swapped successfully
  internal static func swappedSuccessfully(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "%@ → %@ swapped successfully", String(describing: p1), String(describing: p2))
  }
  /// %@-compatible address
  internal static func compatibleAddress(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@-compatible address", String(describing: p1))
  }
  /// %@h ago
  internal static func hAgo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@h ago", String(describing: p1))
  }
  /// %@m ago
  internal static func mAgo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "%@m ago", String(describing: p1))
  }
  /// Plural format key: "%#@variable_0@"
  internal static func dDayAgo(_ p1: Int) -> String {
    return L10n.tr("Localizable", "%d day ago", p1)
  }
  /// Plural format key: "%#@variable_0@"
  internal static func dHiddenWallet(_ p1: Int) -> String {
    return L10n.tr("Localizable", "%d hidden wallet", p1)
  }
  /// Plural format key: "%#@variable_0@"
  internal static func dWallet(_ p1: Int) -> String {
    return L10n.tr("Localizable", "%d wallet", p1)
  }
  /// 1 %@ Price
  internal static func _1Price(_ p1: Any) -> String {
    return L10n.tr("Localizable", "1 %@ Price", String(describing: p1))
  }
  /// 1d
  internal static var _1d: String { L10n.tr("Localizable", "1d") }
  /// 1h
  internal static var _1h: String { L10n.tr("Localizable", "1h") }
  /// 1m
  internal static var _1m: String { L10n.tr("Localizable", "1m") }
  /// 1w
  internal static var _1w: String { L10n.tr("Localizable", "1w") }
  /// 24 hours
  internal static var _24Hours: String { L10n.tr("Localizable", "24 hours") }
  /// 4h
  internal static var _4h: String { L10n.tr("Localizable", "4h") }
  /// A **%@** to receive bitcoins over the Bitcoin network
  internal static func aToReceiveBitcoinsOverTheBitcoinNetwork(_ p1: Any) -> String {
    return L10n.tr("Localizable", "A **%@** to receive bitcoins over the Bitcoin network", String(describing: p1))
  }
  /// A fee paid to the liquidity providers
  internal static var aFeePaidToTheLiquidityProviders: String { L10n.tr("Localizable", "A fee paid to the liquidity providers") }
  /// A proportional amount of rewards will be withdrawn
  internal static var aProportionalAmountOfRewardsWillBeWithdrawn: String { L10n.tr("Localizable", "A proportional amount of rewards will be withdrawn") }
  /// A slippage is the difference between the expected price and the actual price at which a trade is executed
  internal static var aSlippageIsTheDifferenceBetweenTheExpectedPriceAndTheActualPriceAtWhichATradeIsExecuted: String { L10n.tr("Localizable", "A slippage is the difference between the expected price and the actual price at which a trade is executed") }
  /// A wallet found
  internal static var aWalletFound: String { L10n.tr("Localizable", "A wallet found") }
  /// Accept
  internal static var accept: String { L10n.tr("Localizable", "Accept") }
  /// Account creation fee
  internal static var accountCreationFee: String { L10n.tr("Localizable", "Account creation fee") }
  /// Account creation for this address is not possible due to insufficient funds.
  internal static var accountCreationForThisAddressIsNotPossibleDueToInsufficientFunds: String { L10n.tr("Localizable", "Account creation for this address is not possible due to insufficient funds.") }
  /// Account not found
  internal static var accountNotFound: String { L10n.tr("Localizable", "Account not found") }
  /// Actions
  internal static var actions: String { L10n.tr("Localizable", "Actions") }
  /// Activities
  internal static var activities: String { L10n.tr("Localizable", "Activities") }
  /// Activity
  internal static var activity: String { L10n.tr("Localizable", "Activity") }
  /// actual
  internal static var actual: String { L10n.tr("Localizable", "actual") }
  /// Add a phone number to protect your account
  internal static var addAPhoneNumberToProtectYourAccount: String { L10n.tr("Localizable", "Add a phone number to protect your account") }
  /// Add a phone number to restore your account
  internal static var addAPhoneNumberToRestoreYourAccount: String { L10n.tr("Localizable", "Add a phone number to restore your account") }
  /// Add funds
  internal static var addFunds: String { L10n.tr("Localizable", "Add funds") }
  /// Add more
  internal static var addMore: String { L10n.tr("Localizable", "Add more") }
  /// Add token
  internal static var addToken: String { L10n.tr("Localizable", "Add token") }
  /// Add token to see wallet address
  internal static var addTokenToSeeWalletAddress: String { L10n.tr("Localizable", "Add token to see wallet address") }
  /// Add wallet
  internal static var addWallet: String { L10n.tr("Localizable", "Add wallet") }
  /// Adding token to your wallet
  internal static var addingTokenToYourWallet: String { L10n.tr("Localizable", "Adding token to your wallet") }
  /// Address
  internal static var address: String { L10n.tr("Localizable", "Address") }
  /// Address copied to clipboard!
  internal static var addressCopiedToClipboard: String { L10n.tr("Localizable", "Address copied to clipboard!") }
  /// Address copied!
  internal static var addressCopied: String { L10n.tr("Localizable", "Address copied!") }
  /// Address was copied to clipboard
  internal static var addressWasCopiedToClipboard: String { L10n.tr("Localizable", "Address was copied to clipboard") }
  /// After 2 more incorrect PINs we’ll log out current account for your safety
  internal static var after2MoreIncorrectPINsWeLlLogOutCurrentAccountForYourSafety: String { L10n.tr("Localizable", "After 2 more incorrect PINs we’ll log out current account for your safety") }
  /// After 5 incorrect app PINs
  internal static var after5IncorrectAppPINs: String { L10n.tr("Localizable", "After 5 incorrect app PINs") }
  /// After first transaction you will\nbe able to view it here
  internal static var afterFirstTransactionYouWillBeAbleToViewItHere: String { L10n.tr("Localizable", "After first transaction you will\nbe able to view it here") }
  /// all
  internal static var all: String { L10n.tr("Localizable", "all") }
  /// All countries
  internal static var allCountries: String { L10n.tr("Localizable", "All countries") }
  /// All deposits are stored 100%% non-custodiallity with keys held on this device
  internal static var allDepositsAreStored100NonCustodiallityWithKeysHeldOnThisDevice: String { L10n.tr("Localizable", "All deposits are stored 100% non-custodiallity with keys held on this device") }
  /// All fees included %@ %@ ≈ %@ %@
  internal static func allFeesIncluded(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any) -> String {
    return L10n.tr("Localizable", "All fees included %@ %@ ≈ %@ %@", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4))
  }
  /// All my products
  internal static var allMyProducts: String { L10n.tr("Localizable", "All my products") }
  /// All my tokens
  internal static var allMyTokens: String { L10n.tr("Localizable", "All my tokens") }
  /// All the ways to buy
  internal static var allTheWaysToBuy: String { L10n.tr("Localizable", "All the ways to buy") }
  /// All tokens
  internal static var allTokens: String { L10n.tr("Localizable", "All tokens") }
  /// Allow
  internal static var allow: String { L10n.tr("Localizable", "Allow") }
  /// Allow access to save your photos
  internal static var allowAccessToSaveYourPhotos: String { L10n.tr("Localizable", "Allow access to save your photos") }
  /// Allow notifications
  internal static var allowNotifications: String { L10n.tr("Localizable", "Allow notifications") }
  /// Allow push notifications so you don’t miss any important updates on your account.
  internal static var allowPushNotificationsSoYouDonTMissAnyImportantUpdatesOnYourAccount: String { L10n.tr("Localizable", "Allow push notifications so you don’t miss any important updates on your account.") }
  /// Almost done
  internal static var almostDone: String { L10n.tr("Localizable", "Almost done") }
  /// amount
  internal static var amount: String { L10n.tr("Localizable", "amount") }
  /// Amount is not valid
  internal static var amountIsNotValid: String { L10n.tr("Localizable", "Amount is not valid") }
  /// Amount is too small
  internal static var amountIsTooSmall: String { L10n.tr("Localizable", "Amount is too small") }
  /// Amount is too small, expected %@, got %@
  internal static func amountIsTooSmallExpectedGot(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Amount is too small, expected %@, got %@", String(describing: p1), String(describing: p2))
  }
  /// An unexpected error occurred
  internal static var anUnexpectedErrorOccurred: String { L10n.tr("Localizable", "An unexpected error occurred") }
  /// and
  internal static var and: String { L10n.tr("Localizable", "and") }
  /// Any token can be received using username regardless of whether it is in your wallet's list
  internal static var anyTokenCanBeReceivedUsingUsernameRegardlessOfWhetherItIsInYourWalletSList: String { L10n.tr("Localizable", "Any token can be received using username regardless of whether it is in your wallet's list") }
  /// Anyone who gets this one-time link can claim money
  internal static var anyoneWhoGetsThisOneTimeLinkCanClaimMoney: String { L10n.tr("Localizable", "Anyone who gets this one-time link can claim money") }
  /// Anytime you want, you can easily reserve a username by going to the settings
  internal static var anytimeYouWantYouCanEasilyReserveAUsernameByGoingToTheSettings: String { L10n.tr("Localizable", "Anytime you want, you can easily reserve a username by going to the settings") }
  /// App icon
  internal static var appIcon: String { L10n.tr("Localizable", "App icon") }
  /// App version
  internal static var appVersion: String { L10n.tr("Localizable", "App version") }
  /// Appearance
  internal static var appearance: String { L10n.tr("Localizable", "Appearance") }
  /// APY
  internal static var apy: String { L10n.tr("Localizable", "APY") }
  /// Are you sure that this %@ address is valid?
  internal static func areYouSureThatThisAddressIsValid(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Are you sure that this %@ address is valid?", String(describing: p1))
  }
  /// Are you sure you want to delete this token account? This will permanently disable token transfers to this address and remove it from your wallet.
  internal static var areYouSureYouWantToDeleteThisTokenAccountThisWillPermanentlyDisableTokenTransfersToThisAddressAndRemoveItFromYourWallet: String { L10n.tr("Localizable", "Are you sure you want to delete this token account? This will permanently disable token transfers to this address and remove it from your wallet.") }
  /// Are you sure you want to delete your account?
  internal static var areYouSureYouWantToDeleteYourAccount: String { L10n.tr("Localizable", "Are you sure you want to delete your account?") }
  /// Are you sure you want to interrupt cash out process? Your transaction won't be finished.
  internal static var areYouSureYouWantToInterruptCashOutProcessYourTransactionWonTBeFinished: String { L10n.tr("Localizable", "Are you sure you want to interrupt cash out process? Your transaction won't be finished.") }
  /// Are you sure you want to update your authorization device?
  internal static var areYouSureYouWantToUpdateYourAuthorizationDevice: String { L10n.tr("Localizable", "Are you sure you want to update your authorization device?") }
  /// Are you sure?
  internal static var areYouSure: String { L10n.tr("Localizable", "Are you sure?") }
  /// As all your funds are insured, you don’t need to worry anymore
  internal static var asAllYourFundsAreInsuredYouDonTNeedToWorryAnymore: String { L10n.tr("Localizable", "As all your funds are insured, you don’t need to worry anymore") }
  /// Ask a question / Request a feature
  internal static var askAQuestionRequestAFeature: String { L10n.tr("Localizable", "Ask a question / Request a feature") }
  /// Attempt to debit an account but found no record of a prior credit.
  internal static var attemptToDebitAnAccountButFoundNoRecordOfAPriorCredit: String { L10n.tr("Localizable", "Attempt to debit an account but found no record of a prior credit.") }
  /// Attention! If you update your current device, you will not be able to use the old device for recovery.
  internal static var attentionIfYouUpdateYourCurrentDeviceYouWillNotBeAbleToUseTheOldDeviceForRecovery: String { L10n.tr("Localizable", "Attention! If you update your current device, you will not be able to use the old device for recovery.") }
  /// Authentication failed
  internal static var authenticationFailed: String { L10n.tr("Localizable", "Authentication failed") }
  /// Available
  internal static var available: String { L10n.tr("Localizable", "Available") }
  /// Awesome
  internal static var awesome: String { L10n.tr("Localizable", "Awesome") }
  /// Back
  internal static var back: String { L10n.tr("Localizable", "Back") }
  /// Back up your wallet
  internal static var backUpYourWallet: String { L10n.tr("Localizable", "Back up your wallet") }
  /// Backing up
  internal static var backingUp: String { L10n.tr("Localizable", "Backing up") }
  /// Backup
  internal static var backup: String { L10n.tr("Localizable", "Backup") }
  /// Backup is ready
  internal static var backupIsReady: String { L10n.tr("Localizable", "Backup is ready") }
  /// Backup manually
  internal static var backupManually: String { L10n.tr("Localizable", "Backup manually") }
  /// Backup now
  internal static var backupNow: String { L10n.tr("Localizable", "Backup now") }
  /// Backup required
  internal static var backupRequired: String { L10n.tr("Localizable", "Backup required") }
  /// Backup to iCloud
  internal static var backupToICloud: String { L10n.tr("Localizable", "Backup to iCloud") }
  /// Backup using iCloud
  internal static var backupUsingICloud: String { L10n.tr("Localizable", "Backup using iCloud") }
  /// Balance
  internal static var balance: String { L10n.tr("Localizable", "Balance") }
  /// Balances
  internal static var balances: String { L10n.tr("Localizable", "Balances") }
  /// Be sure you can complete this transaction
  internal static var beSureYouCanCompleteThisTransaction: String { L10n.tr("Localizable", "Be sure you can complete this transaction") }
  /// Best price
  internal static var bestPrice: String { L10n.tr("Localizable", "Best price") }
  /// beta
  internal static var beta: String { L10n.tr("Localizable", "beta") }
  /// Bitcoin
  internal static var bitcoin: String { L10n.tr("Localizable", "Bitcoin") }
  /// Bitcoin deposit address
  internal static var bitcoinDepositAddress: String { L10n.tr("Localizable", "Bitcoin deposit address") }
  /// Block number
  internal static var blockNumber: String { L10n.tr("Localizable", "Block number") }
  /// Blockhash not found
  internal static var blockhashNotFound: String { L10n.tr("Localizable", "Blockhash not found") }
  /// Blockhash required
  internal static var blockhashRequired: String { L10n.tr("Localizable", "Blockhash required") }
  /// British pound sterling
  internal static var britishPoundSterling: String { L10n.tr("Localizable", "British pound sterling") }
  /// Burn
  internal static var burn: String { L10n.tr("Localizable", "Burn") }
  /// Burn signature
  internal static var burnSignature: String { L10n.tr("Localizable", "Burn signature") }
  /// but you can send to it multiple times within this session
  internal static var butYouCanSendToItMultipleTimesWithinThisSession: String { L10n.tr("Localizable", "but you can send to it multiple times within this session") }
  /// Buy
  internal static var buy: String { L10n.tr("Localizable", "Buy") }
  /// Buy %@
  internal static func buyOnMoonpay(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Buy %@ on Moonpay", String(describing: p1))
  }
  /// Buy crypto
  internal static var buyCrypto: String { L10n.tr("Localizable", "Buy crypto") }
  /// Buy Cryptos with Credit Card, Fiat or Apple Pay
  internal static var buyCryptosWithCreditCardFiatOrApplePay: String { L10n.tr("Localizable", "Buy Cryptos with Credit Card, Fiat or Apple Pay") }
  /// Buy it
  internal static var buyIt: String { L10n.tr("Localizable", "Buy it") }
  /// Buy or receive to continue
  internal static var buyOrReceiveToContinue: String { L10n.tr("Localizable", "Buy or receive to continue") }
  /// Buy over 150 currencies
  internal static var buyOver150Currencies: String { L10n.tr("Localizable", "Buy over 150 currencies") }
  /// Buy with credit card
  internal static var buyWithCreditCard: String { L10n.tr("Localizable", "Buy with credit card") }
  /// Buy with Moonpay
  internal static var buyWithMoonpay: String { L10n.tr("Localizable", "Buy with Moonpay") }
  /// Buying
  internal static var buying: String { L10n.tr("Localizable", "Buying") }
  /// Buying %@
  internal static func buying(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Buying %@", String(describing: p1))
  }
  /// Buying %@ as the base currency
  internal static func buyingAsTheBaseCurrency(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Buying %@ as the base currency", String(describing: p1))
  }
  /// By continuing, you agree to Key App’s
  internal static var byContinuingYouAgreeToKeyAppS: String { L10n.tr("Localizable", "By continuing, you agree to Key App’s") }
  /// By continuing, you agree to wallet's\n%@
  internal static func byContinuingYouAgreeToWalletS(_ p1: Any) -> String {
    return L10n.tr("Localizable", "By continuing, you agree to wallet's %@", String(describing: p1))
  }
  /// By continuing, you agree to wallet's %@ and %@
  internal static func byContinuingYouAgreeToWalletSAnd(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "By continuing, you agree to wallet's %@ and %@", String(describing: p1), String(describing: p2))
  }
  /// Calculated by subtracting the account creation fee from your balance
  internal static var calculatedBySubtractingTheAccountCreationFeeFromYourBalance: String { L10n.tr("Localizable", "Calculated by subtracting the account creation fee from your balance") }
  /// Calculating fees
  internal static var calculatingFees: String { L10n.tr("Localizable", "Calculating fees") }
  /// Calculating minimum transaction amount…
  internal static var calculatingMinimumTransactionAmount: String { L10n.tr("Localizable", "Calculating minimum transaction amount…") }
  /// Calculating the fees
  internal static var calculatingTheFees: String { L10n.tr("Localizable", "Calculating the fees") }
  /// Cancel
  internal static var cancel: String { L10n.tr("Localizable", "Cancel") }
  /// cannot exceed 50%%
  internal static var cannotExceed50: String { L10n.tr("Localizable", "cannot exceed 50%") }
  /// Terms and Conditions
  internal static var capitalizedTermsAndConditions: String { L10n.tr("Localizable", "Capitalized Terms and Conditions") }
  /// Cash out
  internal static var cashOut: String { L10n.tr("Localizable", "Cash out") }
  /// Cash out %@, receive %@
  internal static func cashOutReceive(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Cash out %@, receive %@", String(describing: p1), String(describing: p2))
  }
  /// Cash out crypto to fiat
  internal static var cashOutCryptoToFiat: String { L10n.tr("Localizable", "Cash out crypto to fiat") }
  /// Cashout with Moonpay
  internal static var cashoutWithMoonpay: String { L10n.tr("Localizable", "Cashout with Moonpay") }
  /// Caution: this address has no funds
  internal static var cautionThisAddressHasNoFunds: String { L10n.tr("Localizable", "Caution: this address has no funds") }
  /// Change
  internal static var change: String { L10n.tr("Localizable", "Change") }
  /// Change my PIN
  internal static var changeMyPIN: String { L10n.tr("Localizable", "Change my PIN") }
  /// Change PIN
  internal static var changePIN: String { L10n.tr("Localizable", "Change PIN") }
  /// Change PIN-code
  internal static var changePINCode: String { L10n.tr("Localizable", "Change PIN-code") }
  /// Change the network?
  internal static var changeTheNetwork: String { L10n.tr("Localizable", "Change the network?") }
  /// Change the region manually
  internal static var changeTheRegionManually: String { L10n.tr("Localizable", "Change the region manually") }
  /// Change the token?
  internal static var changeTheToken: String { L10n.tr("Localizable", "Change the token?") }
  /// Change your search phrase
  internal static var changeYourSearchPhrase: String { L10n.tr("Localizable", "Change your search phrase") }
  /// Change your settings to use camera for scanning Qr Code
  internal static var changeYourSettingsToUseCameraForScanningQrCode: String { L10n.tr("Localizable", "Change your settings to use camera for scanning Qr Code") }
  /// Changed language to %@
  internal static func changedLanguageTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Changed language to %@", String(describing: p1))
  }
  /// Changing currency
  internal static var changingCurrency: String { L10n.tr("Localizable", "Changing currency") }
  /// Check available funds
  internal static var checkAvailableFunds: String { L10n.tr("Localizable", "Check available funds") }
  /// Check enterred wallet address and try again.
  internal static var checkEnterredWalletAddressAndTryAgain: String { L10n.tr("Localizable", "Check enterred wallet address and try again.") }
  /// Checking address' validity
  internal static var checkingAddressValidity: String { L10n.tr("Localizable", "Checking address' validity") }
  /// Checking name’s availability
  internal static var checkingNameSAvailability: String { L10n.tr("Localizable", "Checking name’s availability") }
  /// Chinese Yuan
  internal static var chineseYuan: String { L10n.tr("Localizable", "Chinese Yuan") }
  /// Choose a recipient
  internal static var chooseARecipient: String { L10n.tr("Localizable", "Choose a recipient") }
  /// Choose a token for buying
  internal static var chooseATokenForBuying: String { L10n.tr("Localizable", "Choose a token for buying") }
  /// Choose an option to continue
  internal static var chooseAnOptionToContinue: String { L10n.tr("Localizable", "Choose an option to continue") }
  /// Choose another destination wallet
  internal static var chooseAnotherDestinationWallet: String { L10n.tr("Localizable", "Choose another destination wallet") }
  /// Choose another slippage
  internal static var chooseAnotherSlippage: String { L10n.tr("Localizable", "Choose another slippage") }
  /// Choose available username
  internal static var chooseAvailableUsername: String { L10n.tr("Localizable", "Choose available username") }
  /// Choose destination wallet
  internal static var chooseDestinationWallet: String { L10n.tr("Localizable", "Choose destination wallet") }
  /// Choose network
  internal static var chooseNetwork: String { L10n.tr("Localizable", "Choose network") }
  /// Choose source wallet
  internal static var chooseSourceWallet: String { L10n.tr("Localizable", "Choose source wallet") }
  /// Choose the correct words
  internal static var chooseTheCorrectWords: String { L10n.tr("Localizable", "Choose the correct words") }
  /// Choose the network
  internal static var chooseTheNetwork: String { L10n.tr("Localizable", "Choose the network") }
  /// Choose the recipient
  internal static var chooseTheRecipient: String { L10n.tr("Localizable", "Choose the recipient") }
  /// Choose the recipient to proceed
  internal static var chooseTheRecipientToProceed: String { L10n.tr("Localizable", "Choose the recipient to proceed") }
  /// Choose the token to pay fees
  internal static var chooseTheTokenToPayFees: String { L10n.tr("Localizable", "Choose the token to pay fees") }
  /// Choose wallet
  internal static var chooseWallet: String { L10n.tr("Localizable", "Choose wallet") }
  /// Choose your wallet
  internal static var chooseYourWallet: String { L10n.tr("Localizable", "Choose your wallet") }
  /// Chosen country
  internal static var chosenCountry: String { L10n.tr("Localizable", "Chosen country") }
  /// Chosen token
  internal static var chosenToken: String { L10n.tr("Localizable", "Chosen token") }
  /// Claim
  internal static var claim: String { L10n.tr("Localizable", "Claim") }
  /// Claim %@
  internal static func claim(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Claim %@", String(describing: p1))
  }
  /// Claiming
  internal static var claiming: String { L10n.tr("Localizable", "Claiming") }
  /// classic
  internal static var classic: String { L10n.tr("Localizable", "classic") }
  /// Clear
  internal static var clear: String { L10n.tr("Localizable", "Clear") }
  /// Close
  internal static var close: String { L10n.tr("Localizable", "Close") }
  /// Close %@ account
  internal static func closeAccount(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Close %@ account", String(describing: p1))
  }
  /// Close Account
  internal static var closeAccount: String { L10n.tr("Localizable", "Close account") }
  /// Close token account
  internal static var closeTokenAccount: String { L10n.tr("Localizable", "Close token account") }
  /// Closed wallet
  internal static var closedWallet: String { L10n.tr("Localizable", "Closed wallet") }
  /// Coins to buy
  internal static var coinsToBuy: String { L10n.tr("Localizable", "Coins to buy") }
  /// Receive at least:
  internal static var colonReceiveAtLeast: String { L10n.tr("Localizable", "Colon Receive at least") }
  /// Combined tokens value
  internal static var combinedTokensValue: String { L10n.tr("Localizable", "Combined tokens value") }
  /// Coming soon
  internal static var comingSoon: String { L10n.tr("Localizable", "Coming soon") }
  /// Completed
  internal static var completed: String { L10n.tr("Localizable", "Completed") }
  /// Confirm
  internal static var confirm: String { L10n.tr("Localizable", "Confirm") }
  /// Confirm access to your account that was used to create the wallet
  internal static var confirmAccessToYourAccountThatWasUsedToCreateTheWallet: String { L10n.tr("Localizable", "Confirm access to your account that was used to create the wallet") }
  /// Confirm claiming\nthe tokens
  internal static var confirmClaimingTheTokens: String { L10n.tr("Localizable", "Confirm claiming the tokens ") }
  /// Confirm it's you
  internal static var confirmItSYou: String { L10n.tr("Localizable", "Confirm it's you") }
  /// Confirm PIN-code
  internal static var confirmPINCode: String { L10n.tr("Localizable", "Confirm PIN-code") }
  /// Confirm sending %@
  internal static func confirmSending(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Confirm sending %@", String(describing: p1))
  }
  /// Confirm swapping %@ → %@
  internal static func confirmSwapping(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Confirm swapping %@ → %@", String(describing: p1), String(describing: p2))
  }
  /// Confirm transactions
  internal static var confirmTransactions: String { L10n.tr("Localizable", "Confirm transactions") }
  /// Confirm your new PIN code
  internal static var confirmYourNewPINCode: String { L10n.tr("Localizable", "Confirm your new PIN code") }
  /// Confirm your number
  internal static var confirmYourNumber: String { L10n.tr("Localizable", "Confirm your number") }
  /// Confirm your wallet PIN
  internal static var confirmYourWalletPIN: String { L10n.tr("Localizable", "Confirm your wallet PIN") }
  /// Confirmation Code Limit Hit
  internal static var confirmationCodeLimitHit: String { L10n.tr("Localizable", "Confirmation Code Limit Hit") }
  /// Confirmed
  internal static var confirmed: String { L10n.tr("Localizable", "Confirmed") }
  /// Congratulations!
  internal static var congratulations: String { L10n.tr("Localizable", "Congratulations!") }
  /// Connection problem
  internal static var connectionProblem: String { L10n.tr("Localizable", "Connection problem") }
  /// Connection rate limits exceeded
  internal static var connectionRateLimitsExceeded: String { L10n.tr("Localizable", "Connection rate limits exceeded") }
  /// Contact
  internal static var contact: String { L10n.tr("Localizable", "Contact") }
  /// Continue
  internal static var `continue`: String { L10n.tr("Localizable", "Continue") }
  /// Continue anyway
  internal static var continueAnyway: String { L10n.tr("Localizable", "Continue anyway") }
  /// Continue restoring this wallet
  internal static var continueRestoringThisWallet: String { L10n.tr("Localizable", "Continue restoring this wallet") }
  /// Continue transaction
  internal static var continueTransaction: String { L10n.tr("Localizable", "Continue transaction") }
  /// Continue using phone number
  internal static var continueUsingPhoneNumber: String { L10n.tr("Localizable", "Continue using phone number") }
  /// Continue with %@
  internal static func continueWith(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Continue with %@", String(describing: p1))
  }
  /// Continue with Apple
  internal static var continueWithApple: String { L10n.tr("Localizable", "Continue with Apple") }
  /// Continue with Google
  internal static var continueWithGoogle: String { L10n.tr("Localizable", "Continue with Google") }
  /// Continue with iCloud KeyChain
  internal static var continueWithICloudKeyChain: String { L10n.tr("Localizable", "Continue with iCloud KeyChain") }
  /// Convenient and flexible
  internal static var convenientAndFlexible: String { L10n.tr("Localizable", "Convenient and flexible") }
  /// Copied
  internal static var copied: String { L10n.tr("Localizable", "Copied") }
  /// Copied to clipboard
  internal static var copiedToClipboard: String { L10n.tr("Localizable", "Copied to clipboard") }
  /// Copied to the clipboard
  internal static var copiedToTheClipboard: String { L10n.tr("Localizable", "Copied to the clipboard") }
  /// Copy
  internal static var copy: String { L10n.tr("Localizable", "Copy") }
  /// Copy address
  internal static var copyAddress: String { L10n.tr("Localizable", "Copy address") }
  /// Copy to clipboard
  internal static var copyToClipboard: String { L10n.tr("Localizable", "Copy to clipboard") }
  /// Could not calculate exchange rate or swapping fees from current token pair
  internal static var couldNotCalculateExchangeRateOrSwappingFeesFromCurrentTokenPair: String { L10n.tr("Localizable", "Could not calculate exchange rate or swapping fees from current token pair") }
  /// Could not calculating fees
  internal static var couldNotCalculatingFees: String { L10n.tr("Localizable", "Could not calculating fees") }
  /// Could not connect to wallet
  internal static var couldNotConnectToWallet: String { L10n.tr("Localizable", "Could not connect to wallet") }
  /// Could not create capture session
  internal static var couldNotCreateCaptureSession: String { L10n.tr("Localizable", "Could not create capture session") }
  /// Could not create renBTC token, please try again later
  internal static var couldNotCreateRenBTCTokenPleaseTryAgainLater: String { L10n.tr("Localizable", "Could not create renBTC token, please try again later") }
  /// Could not derivate private key
  internal static var couldNotDerivatePrivateKey: String { L10n.tr("Localizable", "Could not derivate private key") }
  /// Could not retrieve account info
  internal static var couldNotRetrieveAccountInfo: String { L10n.tr("Localizable", "Could not retrieve account info") }
  /// Could not retrieve balance
  internal static var couldNotRetrieveBalance: String { L10n.tr("Localizable", "Could not retrieve balance") }
  /// Could not retrieve exchange rate
  internal static var couldNotRetrieveExchangeRate: String { L10n.tr("Localizable", "Could not retrieve exchange rate") }
  /// Counting...
  internal static var counting: String { L10n.tr("Localizable", "Counting...") }
  /// Country code
  internal static var countryCode: String { L10n.tr("Localizable", "Country code") }
  /// Create a new wallet
  internal static var createANewWallet: String { L10n.tr("Localizable", "Create a new wallet") }
  /// Create a PIN-code to protect your wallet
  internal static var createAPINCodeToProtectYourWallet: String { L10n.tr("Localizable", "Create a PIN-code to protect your wallet") }
  /// Create Account
  internal static var createAccount: String { L10n.tr("Localizable", "Create account") }
  /// Create address
  internal static var createAddress: String { L10n.tr("Localizable", "Create address") }
  /// Create Bitcoin address
  internal static var createBitcoinAddress: String { L10n.tr("Localizable", "Create Bitcoin address") }
  /// Create link
  internal static var createLink: String { L10n.tr("Localizable", "Create link") }
  /// Create name
  internal static var createName: String { L10n.tr("Localizable", "Create name") }
  /// create new wallet
  internal static var createNewWallet: String { L10n.tr("Localizable", "create new wallet") }
  /// Create Token Account
  internal static var createTokenAccount: String { L10n.tr("Localizable", "Create Token Account") }
  /// Create your account in 1 minute
  internal static var createYourAccountIn1Minute: String { L10n.tr("Localizable", "Create your account in 1 minute") }
  /// Create your new PIN code
  internal static var createYourNewPINCode: String { L10n.tr("Localizable", "Create your new PIN code") }
  /// Creating
  internal static var creating: String { L10n.tr("Localizable", "Creating") }
  /// creating an account
  internal static var creatingAnAccount: String { L10n.tr("Localizable", "creating an account") }
  /// Creating Token Account
  internal static var creatingTokenAccount: String { L10n.tr("Localizable", "Creating Token Account") }
  /// Creating transaction failed
  internal static var creatingTransactionFailed: String { L10n.tr("Localizable", "Creating transaction failed") }
  /// Creating wallet
  internal static var creatingWallet: String { L10n.tr("Localizable", "Creating wallet") }
  /// Creating your\none-time link
  internal static var creatingYourOneTimeLink: String { L10n.tr("Localizable", "Creating your\none-time link") }
  /// Creating your link
  internal static var creatingYourLink: String { L10n.tr("Localizable", "Creating your link") }
  /// Currencies available
  internal static var currenciesAvailable: String { L10n.tr("Localizable", "Currencies available") }
  /// Currency
  internal static var currency: String { L10n.tr("Localizable", "Currency") }
  /// Currency changed
  internal static var currencyChanged: String { L10n.tr("Localizable", "Currency changed") }
  /// Current PIN-code
  internal static var currentPINCode: String { L10n.tr("Localizable", "Current PIN-code") }
  /// Current price
  internal static var currentPrice: String { L10n.tr("Localizable", "Current price") }
  /// Custom
  internal static var custom: String { L10n.tr("Localizable", "Custom") }
  /// Custom slippage
  internal static var customSlippage: String { L10n.tr("Localizable", "Custom slippage") }
  /// DApps
  internal static var dApps: String { L10n.tr("Localizable", "DApps") }
  /// Dark
  internal static var dark: String { L10n.tr("Localizable", "Dark") }
  /// Date
  internal static var date: String { L10n.tr("Localizable", "Date") }
  /// day
  internal static var day: String { L10n.tr("Localizable", "day") }
  /// Decimals mismatch
  internal static var decimalsMismatch: String { L10n.tr("Localizable", "Decimals mismatch") }
  /// Decline
  internal static var decline: String { L10n.tr("Localizable", "Decline") }
  /// Default
  internal static var `default`: String { L10n.tr("Localizable", "Default") }
  /// Default secure check
  internal static var defaultSecureCheck: String { L10n.tr("Localizable", "Default secure check") }
  /// Delete
  internal static var delete: String { L10n.tr("Localizable", "Delete") }
  /// Delete my account
  internal static var deleteMyAccount: String { L10n.tr("Localizable", "Delete my account") }
  /// Delete transaction
  internal static var deleteTransaction: String { L10n.tr("Localizable", "Delete transaction") }
  /// Deleting your account will take up to 30 days
  internal static var deletingYourAccountWillTakeUpTo30Days: String { L10n.tr("Localizable", "Deleting your account will take up to 30 days") }
  /// Deposit
  internal static var deposit: String { L10n.tr("Localizable", "Deposit") }
  /// Deposit (will be returned)
  internal static var depositWillBeReturned: String { L10n.tr("Localizable", "Deposit (will be returned)") }
  /// Deposit confirmed
  internal static var depositConfirmed: String { L10n.tr("Localizable", "Deposit confirmed") }
  /// Deposit fees
  internal static var depositFees: String { L10n.tr("Localizable", "Deposit fees") }
  /// Deposit into Solend
  internal static var depositIntoSolend: String { L10n.tr("Localizable", "Deposit into Solend") }
  /// Deposit MAX Amount
  internal static var depositMAXAmount: String { L10n.tr("Localizable", "Deposit MAX Amount") }
  /// Deposit to earn a yield
  internal static var depositToEarnAYield: String { L10n.tr("Localizable", "Deposit to earn a yield") }
  /// Deposit your crypto
  internal static var depositYourCrypto: String { L10n.tr("Localizable", "Deposit your crypto") }
  /// Deposit your tokens and earn
  internal static var depositYourTokensAndEarn: String { L10n.tr("Localizable", "Deposit your tokens and earn") }
  /// Depositing funds failed
  internal static var depositingFundsFailed: String { L10n.tr("Localizable", "Depositing funds failed") }
  /// deprecated
  internal static var deprecated: String { L10n.tr("Localizable", "deprecated") }
  /// Derivable Accounts
  internal static var derivableAccounts: String { L10n.tr("Localizable", "Derivable Accounts") }
  /// Derivation path
  internal static var derivationPath: String { L10n.tr("Localizable", "Derivation path") }
  /// Destination network
  internal static var destinationNetwork: String { L10n.tr("Localizable", "Destination network") }
  /// Details
  internal static var details: String { L10n.tr("Localizable", "Details") }
  /// Device
  internal static var device: String { L10n.tr("Localizable", "Device") }
  /// Devices
  internal static var devices: String { L10n.tr("Localizable", "Devices") }
  /// Didn't get it?
  internal static var didnTGetIt: String { L10n.tr("Localizable", "Didn't get it?") }
  /// Direct %@ address
  internal static func directAddress(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Direct %@ address", String(describing: p1))
  }
  /// Discard
  internal static var discard: String { L10n.tr("Localizable", "Discard") }
  /// Do this later
  internal static var doThisLater: String { L10n.tr("Localizable", "Do this later") }
  /// Do you really want to logout?
  internal static var doYouReallyWantToLogout: String { L10n.tr("Localizable", "Do you really want to logout?") }
  /// Do you really want to switch to
  internal static var doYouReallyWantToSwitchTo: String { L10n.tr("Localizable", "Do you really want to switch to") }
  /// Do you want to log out?
  internal static var doYouWantToLogOut: String { L10n.tr("Localizable", "Do you want to log out?") }
  /// Don't miss out on important updates
  internal static var donTMissOutOnImportantUpdates: String { L10n.tr("Localizable", "Don't miss out on important updates") }
  /// Don't use the same pin for multiple accounts.
  internal static var donTUseTheSamePinForMultipleAccounts: String { L10n.tr("Localizable", "Don't use the same pin for multiple accounts.") }
  /// Done
  internal static var done: String { L10n.tr("Localizable", "Done") }
  /// Done! Refresh the history page for the updated status
  internal static var doneRefreshTheHistoryPageForTheUpdatedStatus: String { L10n.tr("Localizable", "Done! Refresh the history page for the updated status") }
  /// Don’t Allow
  internal static var donTAllow: String { L10n.tr("Localizable", "Don’t Allow") }
  /// Don’t book my name
  internal static var donTBookMyName: String { L10n.tr("Localizable", "Don’t book my name") }
  /// Don’t go over the available funds
  internal static var donTGoOverTheAvailableFunds: String { L10n.tr("Localizable", "Don’t go over the available funds") }
  /// don’t have funds
  internal static var donTHaveFunds: String { L10n.tr("Localizable", "don’t have funds") }
  /// Don’t show me again
  internal static var donTShowMeAgain: String { L10n.tr("Localizable", "Don’t show me again") }
  /// Earn
  internal static var earn: String { L10n.tr("Localizable", "Earn") }
  /// Earn a yield
  internal static var earnAYield: String { L10n.tr("Localizable", "Earn a yield") }
  /// Earn balance
  internal static var earnBalance: String { L10n.tr("Localizable", "Earn balance") }
  /// Earn interest on your crypto
  internal static var earnInterestOnYourCrypto: String { L10n.tr("Localizable", "Earn interest on your crypto") }
  /// Earn on your funds
  internal static var earnOnYourFunds: String { L10n.tr("Localizable", "Earn on your funds") }
  /// Earn up to %@ on %@
  internal static func earnUpToOn(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Earn up to %@ on %@", String(describing: p1), String(describing: p2))
  }
  /// Earn up to %@%%
  internal static func earnUpTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Earn up to %@%%", String(describing: p1))
  }
  /// Easy swap with credit card or bank transfer
  internal static var easySwapWithCreditCardOrBankTransfer: String { L10n.tr("Localizable", "Easy swap with credit card or bank transfer") }
  /// Easy to start
  internal static var easyToStart: String { L10n.tr("Localizable", "Easy to start") }
  /// Easy way to earn, invest & send crypto with zero fees
  internal static var easyWayToEarnInvestAndSendCryptoWithZeroFees: String { L10n.tr("Localizable", "Easy way to earn, invest and send crypto with zero fees") }
  /// Easy way to invest
  internal static var easyWayToInvest: String { L10n.tr("Localizable", "Easy way to invest") }
  /// Effortlessly send tokens with usernames\ninstead of long addresses
  internal static var effortlesslySendTokensWithUsernamesInsteadOfLongAddresses: String { L10n.tr("Localizable", "Effortlessly send tokens with usernames\ninstead of long addresses") }
  /// Enable FaceID
  internal static var enableFaceID: String { L10n.tr("Localizable", "Enable FaceID") }
  /// Enable now
  internal static var enableNow: String { L10n.tr("Localizable", "Enable now") }
  /// Enable TouchID
  internal static var enableTouchID: String { L10n.tr("Localizable", "Enable TouchID") }
  /// Enjoy free transactions
  internal static var enjoyFreeTransactions: String { L10n.tr("Localizable", "Enjoy free transactions") }
  /// Enter a number less than %d%
  internal static func enterANumberLessThanD(_ p1: Int) -> String {
    return L10n.tr("Localizable", "Enter a number less than %d%", p1)
  }
  /// Enter a seed phrase from your account
  internal static var enterASeedPhraseFromYourAccount: String { L10n.tr("Localizable", "Enter a seed phrase from your account") }
  /// Enter amount
  internal static var enterAmount: String { L10n.tr("Localizable", "Enter amount") }
  /// Enter correct security key
  internal static var enterCorrectSecurityKey: String { L10n.tr("Localizable", "Enter correct security key") }
  /// Enter current PIN
  internal static var enterCurrentPIN: String { L10n.tr("Localizable", "Enter current PIN") }
  /// Enter greater value
  internal static var enterGreaterValue: String { L10n.tr("Localizable", "Enter greater value") }
  /// Enter input amount
  internal static var enterInputAmount: String { L10n.tr("Localizable", "Enter input amount") }
  /// Enter PIN-code
  internal static var enterPINCode: String { L10n.tr("Localizable", "Enter PIN-code") }
  /// Enter security keys
  internal static var enterSecurityKeys: String { L10n.tr("Localizable", "Enter security keys") }
  /// Enter seed phrases in a correct order to recover your wallet
  internal static var enterSeedPhrasesInACorrectOrderToRecoverYourWallet: String { L10n.tr("Localizable", "Enter seed phrases in a correct order to recover your wallet") }
  /// Enter the amount to proceed
  internal static var enterTheAmountToProceed: String { L10n.tr("Localizable", "Enter the amount to proceed") }
  /// Enter the code to continue
  internal static var enterTheCodeToContinue: String { L10n.tr("Localizable", "Enter the code to continue") }
  /// Enter the correct amount to continue
  internal static var enterTheCorrectAmountToContinue: String { L10n.tr("Localizable", "Enter the correct amount to continue") }
  /// Enter the number to continue
  internal static var enterTheNumberToContinue: String { L10n.tr("Localizable", "Enter the number to continue") }
  /// Enter the recipient's address
  internal static var enterTheRecipientSAddress: String { L10n.tr("Localizable", "Enter the recipient's address") }
  /// Enter username
  internal static var enterUsername: String { L10n.tr("Localizable", "Enter username") }
  /// Enter username or skip
  internal static var enterUsernameOrSkip: String { L10n.tr("Localizable", "Enter username or skip") }
  /// Enter your PIN
  internal static var enterYourPIN: String { L10n.tr("Localizable", "Enter your PIN") }
  /// Enter your security key
  internal static var enterYourSecurityKey: String { L10n.tr("Localizable", "Enter your security key") }
  /// Enter your seed phrase
  internal static var enterYourSeedPhrase: String { L10n.tr("Localizable", "Enter your seed phrase") }
  /// Enter your Solana wallet seed phrase
  internal static var enterYourSolanaWalletSeedPhrase: String { L10n.tr("Localizable", "Enter your Solana wallet seed phrase") }
  /// error
  internal static var error: String { L10n.tr("Localizable", "error") }
  /// Error fetching market %@
  internal static func errorFetchingMarket(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Error fetching market %@", String(describing: p1))
  }
  /// Error processing instruction 0:custom program error: 0x1
  internal static var errorProcessingInstruction0CustomProgramError0x1: String { L10n.tr("Localizable", "Error processing instruction 0:custom program error: 0x1") }
  /// Error retrieving receipt
  internal static var errorRetrievingReceipt: String { L10n.tr("Localizable", "Error retrieving receipt") }
  /// Error sending transaction
  internal static var errorSendingTransaction: String { L10n.tr("Localizable", "Error sending transaction") }
  /// Error when updating prices
  internal static var errorWhenUpdatingPrices: String { L10n.tr("Localizable", "Error when updating prices") }
  /// Error: %@
  internal static func error(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Error: %@", String(describing: p1))
  }
  /// Estimated fees
  internal static var estimatedFees: String { L10n.tr("Localizable", "Estimated fees") }
  /// Estimating...
  internal static var estimating: String { L10n.tr("Localizable", "Estimating...") }
  /// Euro
  internal static var euro: String { L10n.tr("Localizable", "Euro") }
  /// Everything is broken
  internal static var everythingIsBroken: String { L10n.tr("Localizable", "Everything is broken") }
  /// Exceeded maximum number of instructions allowed
  internal static var exceededMaximumNumberOfInstructionsAllowed: String { L10n.tr("Localizable", "Exceeded maximum number of instructions allowed") }
  /// Exchange
  internal static var exchange: String { L10n.tr("Localizable", "Exchange") }
  /// Exchange rate
  internal static var exchangeRate: String { L10n.tr("Localizable", "Exchange rate") }
  /// Exchange rate is not valid
  internal static var exchangeRateIsNotValid: String { L10n.tr("Localizable", "Exchange rate is not valid") }
  /// Exchanging %@ → %@
  internal static func exchanging(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Exchanging %@ → %@", String(describing: p1), String(describing: p2))
  }
  /// Excluding fees you will deposit
  internal static var excludingFeesYouWillDeposit: String { L10n.tr("Localizable", "Excluding fees you will deposit") }
  /// Excluding fees, you'll deposit
  internal static var excludingFeesYouLlDeposit: String { L10n.tr("Localizable", "Excluding fees, you'll deposit") }
  /// expected
  internal static var expected: String { L10n.tr("Localizable", "expected") }
  /// Explore DeFi
  internal static var exploreDeFi: String { L10n.tr("Localizable", "Explore DeFi") }
  /// Explorer
  internal static var explorer: String { L10n.tr("Localizable", "Explorer") }
  /// Face ID
  internal static var faceID: String { L10n.tr("Localizable", "Face ID") }
  /// Failed to get data
  internal static var failedToGetData: String { L10n.tr("Localizable", "Failed to get data") }
  /// Fee
  internal static var fee: String { L10n.tr("Localizable", "Fee") }
  /// Fee calculator not found
  internal static var feeCalculatorNotFound: String { L10n.tr("Localizable", "Fee calculator not found") }
  /// Fee compensation pool not found
  internal static var feeCompensationPoolNotFound: String { L10n.tr("Localizable", "Fee compensation pool not found") }
  /// Feedback
  internal static var feedback: String { L10n.tr("Localizable", "Feedback") }
  /// Fees
  internal static var fees: String { L10n.tr("Localizable", "Fees") }
  /// Fees: %@
  internal static func fees(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Fees: %@", String(describing: p1))
  }
  /// Fetching receipt
  internal static var fetchingReceipt: String { L10n.tr("Localizable", "Fetching receipt") }
  /// Fill 12 or 24 words
  internal static var fill12Or24Words: String { L10n.tr("Localizable", "Fill 12 or 24 words") }
  /// Finding swapping routes
  internal static var findingSwappingRoutes: String { L10n.tr("Localizable", "Finding swapping routes") }
  /// Finish setup
  internal static var finishSetup: String { L10n.tr("Localizable", "Finish setup") }
  /// Follow us on Twitter
  internal static var followUsOnTwitter: String { L10n.tr("Localizable", "Follow us on Twitter") }
  /// For security, change your authorization device to restore access For security, change your authorization device to restore access if needed.
  internal static var forSecurityChangeYourAuthorizationDeviceToRestoreAccessForSecurityChangeYourAuthorizationDeviceToRestoreAccessIfNeeded: String { L10n.tr("Localizable", "For security, change your authorization device to restore access For security, change your authorization device to restore access if needed.") }
  /// For security, change your authorization device to restore access if needed.
  internal static var forSecurityChangeYourAuthorizationDeviceToRestoreAccessIfNeeded: String { L10n.tr("Localizable", "For security, change your authorization device to restore access if needed.") }
  /// for the last 24 hours
  internal static var forTheLast24Hours: String { L10n.tr("Localizable", "for the last 24 hours") }
  /// Forgot your PIN?
  internal static var forgotYourPIN: String { L10n.tr("Localizable", "Forgot your PIN?") }
  /// found
  internal static var found: String { L10n.tr("Localizable", "found") }
  /// Found associated wallet address
  internal static var foundAssociatedWalletAddress: String { L10n.tr("Localizable", "Found associated wallet address") }
  /// Free
  internal static var free: String { L10n.tr("Localizable", "Free") }
  /// Free (%@ left for today)
  internal static func freeLeftForToday(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Free (%@ left for today)", String(describing: p1))
  }
  /// Free (Paid by Key App)
  internal static var freePaidByKeyApp: String { L10n.tr("Localizable", "Free (Paid by Key App)") }
  /// Free by Key App
  internal static var freeByKeyApp: String { L10n.tr("Localizable", "Free by Key App") }
  /// French Franc
  internal static var frenchFranc: String { L10n.tr("Localizable", "French Franc") }
  /// Friends
  internal static var friends: String { L10n.tr("Localizable", "Friends") }
  /// From
  internal static var from: String { L10n.tr("Localizable", "From") }
  /// From %@
  internal static func from(_ p1: Any) -> String {
    return L10n.tr("Localizable", "From %@", String(describing: p1))
  }
  /// from 6 till 15 characters 👌
  internal static var from6Till15Characters👌: String { L10n.tr("Localizable", "from 6 till 15 characters 👌") }
  /// from another wallet or exchange
  internal static var fromAnotherWalletOrExchange: String { L10n.tr("Localizable", "from another wallet or exchange") }
  /// From %@
  internal static func fromToken(_ p1: Any) -> String {
    return L10n.tr("Localizable", "From token %@", String(describing: p1))
  }
  /// frontrun
  internal static var frontrun: String { L10n.tr("Localizable", "frontrun") }
  /// Funds were sent
  internal static var fundsWereSent: String { L10n.tr("Localizable", "Funds were sent") }
  /// Get up to 8%% APY on staking USDC
  internal static var getUpTo8APYOnStakingUSDC: String { L10n.tr("Localizable", "Get up to 8%% APY on staking USDC") }
  /// Get your your own short crypto address
  internal static var getYourYourOwnShortCryptoAddress: String { L10n.tr("Localizable", "Get your your own short crypto address") }
  /// Getting creation fee
  internal static var gettingCreationFee: String { L10n.tr("Localizable", "Getting creation fee") }
  /// Given pool token amount results in zero trading tokens
  internal static var givenPoolTokenAmountResultsInZeroTradingTokens: String { L10n.tr("Localizable", "Given pool token amount results in zero trading tokens") }
  /// Go back
  internal static var goBack: String { L10n.tr("Localizable", "Go back") }
  /// Go back to profile
  internal static var goBackToProfile: String { L10n.tr("Localizable", "Go back to profile") }
  /// Go back to wallet
  internal static var goBackToWallet: String { L10n.tr("Localizable", "Go back to wallet") }
  /// Go to wallet
  internal static var goToWallet: String { L10n.tr("Localizable", "Go to wallet") }
  /// Got it
  internal static var gotIt: String { L10n.tr("Localizable", "Got it") }
  /// Great!
  internal static var great: String { L10n.tr("Localizable", "Great!") }
  /// Grow your portfolio by receiving rewards up to %@%%
  internal static func growYourPortfolioByReceivingRewardsUpTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Grow your portfolio by receiving rewards up to %@%", String(describing: p1))
  }
  /// Here’s what we found
  internal static var hereSWhatWeFound: String { L10n.tr("Localizable", "Here’s what we found") }
  /// Hey, I've sent you %@ %@! Get it here: %@
  internal static func heyIVeSentYouGetItHere(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "Hey, I've sent you %@ %@! Get it here: %@", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Hidden
  internal static var hidden: String { L10n.tr("Localizable", "Hidden") }
  /// Hidden tokens
  internal static var hiddenTokens: String { L10n.tr("Localizable", "Hidden tokens") }
  /// Hidden wallets
  internal static var hiddenWallets: String { L10n.tr("Localizable", "Hidden wallets") }
  /// Hide
  internal static var hide: String { L10n.tr("Localizable", "Hide") }
  /// Hide address detail
  internal static var hideAddressDetail: String { L10n.tr("Localizable", "Hide address detail") }
  /// Hide details
  internal static var hideDetails: String { L10n.tr("Localizable", "Hide details") }
  /// Hide direct and mint addresses
  internal static var hideDirectAndMintAddresses: String { L10n.tr("Localizable", "Hide direct and mint addresses") }
  /// Hide fees
  internal static var hideFees: String { L10n.tr("Localizable", "Hide fees") }
  /// Hide transaction details
  internal static var hideTransactionDetails: String { L10n.tr("Localizable", "Hide transaction details") }
  /// Hide zero balances
  internal static var hideZeroBalances: String { L10n.tr("Localizable", "Hide zero balances") }
  /// higher volatility
  internal static var higherVolatility: String { L10n.tr("Localizable", "higher volatility") }
  /// History
  internal static var history: String { L10n.tr("Localizable", "History") }
  /// Home
  internal static var home: String { L10n.tr("Localizable", "Home") }
  /// How to claim for free
  internal static var howToClaimForFree: String { L10n.tr("Localizable", "How to claim for free") }
  /// How to continue?
  internal static var howToContinue: String { L10n.tr("Localizable", "How to continue?") }
  /// I already have a wallet
  internal static var iAlreadyHaveAWallet: String { L10n.tr("Localizable", "I already have a wallet") }
  /// I can complete this transaction within time
  internal static var iCanCompleteThisTransactionWithinTime: String { L10n.tr("Localizable", "I can complete this transaction within time") }
  /// I forgot PIN
  internal static var iForgotPIN: String { L10n.tr("Localizable", "I forgot PIN") }
  /// I have saved these words in a safe place
  internal static var iHaveSavedTheseWordsInASafePlace: String { L10n.tr("Localizable", "I have saved these words in a safe place") }
  /// I understand
  internal static var iUnderstand: String { L10n.tr("Localizable", "I understand") }
  /// I want to receive
  internal static var iWantToReceive: String { L10n.tr("Localizable", "I want to receive") }
  /// I want to receive renBTC
  internal static var iWantToReceiveRenBTC: String { L10n.tr("Localizable", "I want to receive renBTC") }
  /// I'm sure, It's correct
  internal static var imSureItSCorrect: String { L10n.tr("Localizable", "I'm sure, It's correct") }
  /// Identify yourself!
  internal static var identifyYourself: String { L10n.tr("Localizable", "Identify yourself!") }
  ///  · If lost, no one can restore it\n · Keep it private, even from us
  internal static var ifLostNoOneCanRestoreItKeepItPrivateEvenFromUs: String { L10n.tr("Localizable", "If lost, no one can restore it Keep it private, even from us") }
  /// If the network is changed to %@, the address field must be filled in with a %@.
  internal static func ifTheNetworkIsChangedToTheAddressFieldMustBeFilledInWithA(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "If the network is changed to %@, the address field must be filled in with a %@.", String(describing: p1), String(describing: p2))
  }
  /// If the token is changed to %@, the address field must be filled in with a %@.
  internal static func ifTheTokenIsChangedToTheAddressFieldMustBeFilledInWithA(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "If the token is changed to %@, the address field must be filled in with a %@.", String(describing: p1), String(describing: p2))
  }
  /// If there is a token named “%@“, we don't recommend sending it to your Solana address since it will most likely be lost forever.
  internal static func ifThereIsATokenNamedWeDonTRecommendSendingItToYourSolanaAddressSinceItWillMostLikelyBeLostForever(_ p1: Any) -> String {
    return L10n.tr("Localizable", "If there is a token named “%@“, we don't recommend sending it to your Solana address since it will most likely be lost forever.", String(describing: p1))
  }
  /// If you cannot complete this transaction within the required time, please return at a later date.
  internal static var ifYouCannotCompleteThisTransactionWithinTheRequiredTimePleaseReturnAtALaterDate: String { L10n.tr("Localizable", "If you cannot complete this transaction within the required time, please return at a later date.") }
  /// If you create a new wallet account, you will receive your security key that you must write down somewhere safe. This is the only way to recover your wallet.\n\nIf you still have access to your old wallet, sometimes you can recover your security key from it.\n\nUsing Custodian wallet, you still have the option to regain access to your data by asking a third party.
  internal static var ifYouCreateANewWalletAccount: String { L10n.tr("Localizable", "If you create a new wallet account") }
  /// If you do not finish your transaction within this period/session/time frame, you risk losing the deposits.
  internal static var ifYouDoNotFinishYourTransactionWithinThisPeriodSessionTimeFrameYouRiskLosingTheDeposits: String { L10n.tr("Localizable", "If you do not finish your transaction within this period/session/time frame, you risk losing the deposits.") }
  /// If you forget your PIN, you can log out and create a new one when you log in again.
  internal static var ifYouForgetYourPINYouCanLogOutAndCreateANewOneWhenYouLogInAgain: String { L10n.tr("Localizable", "If you forget your PIN, you can log out and create a new one when you log in again.") }
  /// If you have no backup, you may never be able to access this account.
  internal static var ifYouHaveNoBackupYouMayNeverBeAbleToAccessThisAccount: String { L10n.tr("Localizable", "If you have no backup, you may never be able to access this account.") }
  /// If you lose this device, you can recover your encrypted wallet backup from iCloud
  internal static var ifYouLoseThisDeviceYouCanRecoverYourEncryptedWalletBackupFromICloud: String { L10n.tr("Localizable", "If you lose this device, you can recover your encrypted wallet backup from iCloud") }
  /// If you lose this device, you can recover your encrypted wallet by using iCloud or mannually inputing your secret phrases
  internal static var ifYouLoseThisDeviceYouCanRecoverYourEncryptedWalletByUsingICloudOrMannuallyInputingYourSecretPhrases: String { L10n.tr("Localizable", "If you lose this device, you can recover your encrypted wallet by using iCloud or mannually inputing your secret phrases") }
  /// If you want to continue with
  internal static var ifYouWantToContinueWith: String { L10n.tr("Localizable", "If you want to continue with") }
  /// If you want to get your money back just open the link by yourself
  internal static var ifYouWantToGetYourMoneyBackJustOpenTheLinkByYourself: String { L10n.tr("Localizable", "If you want to get your money back just open the link by yourself") }
  /// Import a wallet
  internal static var importAWallet: String { L10n.tr("Localizable", "Import a wallet") }
  /// Included fee %@
  internal static func includedFee(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Included fee %@", String(describing: p1))
  }
  /// Incorrect %@ account
  internal static func incorrectAccount(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Incorrect %@ account", String(describing: p1))
  }
  /// Incorrect %@ ID
  internal static func incorrectID(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Incorrect %@ ID", String(describing: p1))
  }
  /// Incorrect account's owner
  internal static var incorrectAccountSOwner: String { L10n.tr("Localizable", "Incorrect account's owner") }
  /// Incorrect PIN, try again (%@ attempt left)
  internal static func incorrectPINTryAgainAttemptLeft(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Incorrect PIN, try again (%@ attempt left)", String(describing: p1))
  }
  /// Incorrect PIN-code
  internal static var incorrectPINCode: String { L10n.tr("Localizable", "Incorrect PIN-code") }
  /// Incorrect SMS code 😬
  internal static var incorrectSMSCode😬: String { L10n.tr("Localizable", "Incorrect SMS code 😬") }
  /// Increase maximum price slippage
  internal static var increaseMaximumPriceSlippage: String { L10n.tr("Localizable", "Increase maximum price slippage") }
  /// Increase slippage and try again
  internal static var increaseSlippageAndTryAgain: String { L10n.tr("Localizable", "Increase slippage and try again") }
  /// Info
  internal static var info: String { L10n.tr("Localizable", "Info") }
  /// Initializing error
  internal static var initializingError: String { L10n.tr("Localizable", "Initializing error") }
  /// Input amount is not valid
  internal static var inputAmountIsNotValid: String { L10n.tr("Localizable", "Input amount is not valid") }
  /// Input amount is too small, minimum amount for swapping is %@
  internal static func inputAmountIsTooSmallMinimumAmountForSwappingIs(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Input amount is too small, minimum amount for swapping is %@", String(describing: p1))
  }
  /// Instead of a PIN, you can access the app using %@
  internal static func insteadOfAPINYouCanAccessTheAppUsing(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Instead of a PIN, you can access the app using %@", String(describing: p1))
  }
  /// Insufficient funds
  internal static var insufficientFunds: String { L10n.tr("Localizable", "Insufficient funds") }
  /// Insufficient funds for fee
  internal static var insufficientFundsForFee: String { L10n.tr("Localizable", "Insufficient funds for fee") }
  /// Insufficient funds to cover fees
  internal static var insufficientFundsToCoverFees: String { L10n.tr("Localizable", "Insufficient funds to cover fees") }
  /// Integrity of the route has been compromised
  internal static var integrityOfTheRouteHasBeenCompromised: String { L10n.tr("Localizable", "Integrity of the route has been compromised") }
  /// Interface language changed
  internal static var interfaceLanguageChanged: String { L10n.tr("Localizable", "Interface language changed") }
  /// Internal Error
  internal static var internalError: String { L10n.tr("Localizable", "Internal Error") }
  /// Interrupt
  internal static var interrupt: String { L10n.tr("Localizable", "Interrupt") }
  /// Invalid account info
  internal static var invalidAccountInfo: String { L10n.tr("Localizable", "Invalid account info") }
  /// Invalid estimated amount
  internal static var invalidEstimatedAmount: String { L10n.tr("Localizable", "Invalid estimated amount") }
  /// Invalid params
  internal static var invalidParams: String { L10n.tr("Localizable", "Invalid params") }
  /// Invalid request
  internal static var invalidRequest: String { L10n.tr("Localizable", "Invalid request") }
  /// Invalid status code
  internal static var invalidStatusCode: String { L10n.tr("Localizable", "Invalid status code") }
  /// Invalid URL
  internal static var invalidURL: String { L10n.tr("Localizable", "Invalid URL") }
  /// Invisible
  internal static var invisible: String { L10n.tr("Localizable", "Invisible") }
  /// is only open for 36 hours
  internal static var isOnlyOpenFor36Hours: String { L10n.tr("Localizable", "is only open for 36 hours") }
  /// It must be an %@ wallet address
  internal static func itMustBeAnWalletAddress(_ p1: Any) -> String {
    return L10n.tr("Localizable", "It must be an %@ wallet address ", String(describing: p1))
  }
  /// It usually takes 15-20 minutes for a transaction to complete
  internal static var itUsuallyTakes1520MinutesForATransactionToComplete: String { L10n.tr("Localizable", "It usually takes 15-20 minutes for a transaction to complete") }
  /// It usually takes few seconds for a transaction to complete
  internal static var itUsuallyTakesFewSecondsForATransactionToComplete: String { L10n.tr("Localizable", "It usually takes few seconds for a transaction to complete") }
  /// It’s a **one-time address**, so if you send multiple transactions, your money will be lost.
  internal static var itSAOneTimeAddressSoIfYouSendMultipleTransactionsYourMoneyWillBeLost: String { L10n.tr("Localizable", "It’s a **one-time address**, so if you send multiple transactions, your money will be lost.") }
  /// It’s okay to be wrong
  internal static var itSOkayToBeWrong: String { L10n.tr("Localizable", "It’s okay to be wrong") }
  /// Join our Discord
  internal static var joinOurDiscord: String { L10n.tr("Localizable", "Join our Discord") }
  /// just now
  internal static var justNow: String { L10n.tr("Localizable", "just now") }
  /// Keep control of your assets with instant withdrawals at any time.
  internal static var keepControlOfYourAssetsWithInstantWithdrawalsAtAnyTime: String { L10n.tr("Localizable", "Keep control of your assets with instant withdrawals at any time.") }
  /// Keep it private, even from us
  internal static var keepItPrivateEvenFromUs: String { L10n.tr("Localizable", "Keep it private, even from us") }
  /// Key App
  internal static var keyApp: String { L10n.tr("Localizable", "Key App") }
  /// Key App doesn’t make any profit from this swap 💚
  internal static var keyAppDoesnTMakeAnyProfitFromThisSwap💚: String { L10n.tr("Localizable", "Key App doesn’t make any profit from this swap 💚") }
  /// Key App one-time transfer link
  internal static var keyAppOneTimeTransferLink: String { L10n.tr("Localizable", "Key App one-time transfer link") }
  /// Key App’s
  internal static var keyAppS: String { L10n.tr("Localizable", "Key App’s") }
  /// Language
  internal static var language: String { L10n.tr("Localizable", "Language") }
  /// Learn more
  internal static var learnMore: String { L10n.tr("Localizable", "Learn more") }
  /// Leave
  internal static var leave: String { L10n.tr("Localizable", "Leave") }
  /// Leave feedback
  internal static var leaveFeedback: String { L10n.tr("Localizable", "Leave feedback") }
  /// Leave this page?
  internal static var leaveThisPage: String { L10n.tr("Localizable", "Leave this page?") }
  /// Less than %@
  internal static func lessThan(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Less than %@", String(describing: p1))
  }
  /// Let your crypto work for you
  internal static var letYourCryptoWorkForYou: String { L10n.tr("Localizable", "Let your crypto work for you") }
  /// Let's go
  internal static var letSGo: String { L10n.tr("Localizable", "Let's go") }
  /// Let’s continue
  internal static var letSContinue: String { L10n.tr("Localizable", "Let’s continue") }
  /// Let’s stay in touch
  internal static var letSStayInTouch: String { L10n.tr("Localizable", "Let’s stay in touch") }
  /// License
  internal static var license: String { L10n.tr("Localizable", "License") }
  /// Light
  internal static var light: String { L10n.tr("Localizable", "Light") }
  /// Liquidity fee
  internal static var liquidityFee: String { L10n.tr("Localizable", "Liquidity fee") }
  /// Liquidity provider fee
  internal static var liquidityProviderFee: String { L10n.tr("Localizable", "Liquidity provider fee") }
  /// List of supported tokens
  internal static var listOfSupportedTokens: String { L10n.tr("Localizable", "List of supported tokens") }
  /// Loading
  internal static var loading: String { L10n.tr("Localizable", "Loading") }
  /// Loading exchange rate
  internal static var loadingExchangeRate: String { L10n.tr("Localizable", "Loading exchange rate") }
  /// Log out
  internal static var logOut: String { L10n.tr("Localizable", "Log out") }
  /// Looks like you already have a wallet with
  internal static var looksLikeYouAlreadyHaveAWalletWith: String { L10n.tr("Localizable", "Looks like you already have a wallet with") }
  /// Looks like you already have a wallet, but you still can create another one
  internal static var looksLikeYouAlreadyHaveAWalletButYouStillCanCreateAnotherOne: String { L10n.tr("Localizable", "Looks like you already have a wallet, but you still can create another one") }
  /// Low slippage caused the swap to fail
  internal static var lowSlippageCausedTheSwapToFail: String { L10n.tr("Localizable", "Low slippage caused the swap to fail") }
  /// Make another swap
  internal static var makeAnotherSwap: String { L10n.tr("Localizable", "Make another swap") }
  /// Make another transaction
  internal static var makeAnotherTransaction: String { L10n.tr("Localizable", "Make another transaction") }
  /// Make sure this is still your device
  internal static var makeSureThisIsStillYourDevice: String { L10n.tr("Localizable", "Make sure this is still your device") }
  /// Make sure you understand
  internal static var makeSureYouUnderstand: String { L10n.tr("Localizable", "Make sure you understand") }
  /// Make sure you understand the aspects
  internal static var makeSureYouUnderstandTheAspects: String { L10n.tr("Localizable", "Make sure you understand the aspects") }
  /// Make sure you understand these aspects
  internal static var makeSureYouUnderstandTheseAspects: String { L10n.tr("Localizable", "Make sure you understand these aspects") }
  /// Make your crypto working on you
  internal static var makeYourCryptoWorkingOnYou: String { L10n.tr("Localizable", "Make your crypto working on you") }
  /// Make your first deposit or buy crypto\nwith your credit card or Apple pay
  internal static var makeYourFirstDepositOrBuyCryptoWithYourCreditCardOrApplePay: String { L10n.tr("Localizable", "Make your first deposit or buy crypto\nwith your credit card or Apple pay") }
  /// Make your first transaction
  internal static var makeYourFirstTransaction: String { L10n.tr("Localizable", "Make your first transaction") }
  /// Max
  internal static var max: String { L10n.tr("Localizable", "Max") }
  /// MAX amount is
  internal static var maxAmountIs: String { L10n.tr("Localizable", "MAX amount is") }
  /// Max price slippage
  internal static var maxPriceSlippage: String { L10n.tr("Localizable", "Max price slippage") }
  /// Max: %@
  internal static func max(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Max: %@", String(describing: p1))
  }
  /// Maximum 15 latin characters and hyphens
  internal static var maximum15LatinCharactersAndHyphens: String { L10n.tr("Localizable", "Maximum 15 latin characters and hyphens") }
  /// Maximum transaction is %@
  internal static func maximumTransactionIs(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Maximum transaction is %@", String(describing: p1))
  }
  /// Method
  internal static var method: String { L10n.tr("Localizable", "Method") }
  /// Method not found
  internal static var methodNotFound: String { L10n.tr("Localizable", "Method not found") }
  /// Min: %@
  internal static func min(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Min: %@", String(describing: p1))
  }
  /// Minimal transaction is %@
  internal static func minimalTransactionIs(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Minimal transaction is %@", String(describing: p1))
  }
  /// minimum
  internal static var minimum: String { L10n.tr("Localizable", "minimum") }
  /// Minimum purchase of %@ required.
  internal static func minimumPurchaseOfRequired(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Minimum purchase of %@ required.", String(describing: p1))
  }
  /// Minimum receive
  internal static var minimumReceive: String { L10n.tr("Localizable", "Minimum receive") }
  /// Minimum received
  internal static var minimumReceived: String { L10n.tr("Localizable", "Minimum received") }
  /// Minimum transaction amount of **%@**.
  internal static func minimumTransactionAmountOf(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Minimum transaction amount of %@", String(describing: p1))
  }
  /// Mint
  internal static var mint: String { L10n.tr("Localizable", "Mint") }
  /// Mint address
  internal static var mintAddress: String { L10n.tr("Localizable", "Mint address") }
  /// Mint signature
  internal static var mintSignature: String { L10n.tr("Localizable", "Mint signature") }
  /// Minting
  internal static var minting: String { L10n.tr("Localizable", "Minting") }
  /// minutes
  internal static var minutes: String { L10n.tr("Localizable", "minutes") }
  /// month
  internal static var month: String { L10n.tr("Localizable", "month") }
  /// Moonpay help center
  internal static var moonpayHelpCenter: String { L10n.tr("Localizable", "Moonpay help center") }
  /// More than the received amount
  internal static var moreThanTheReceivedAmount: String { L10n.tr("Localizable", "More than the received amount") }
  /// Multi-factor authentication
  internal static var multiFactorAuthentication: String { L10n.tr("Localizable", "Multi-factor authentication") }
  /// Multiple wallets found
  internal static var multipleWalletsFound: String { L10n.tr("Localizable", "Multiple wallets found") }
  /// My balances
  internal static var myBalances: String { L10n.tr("Localizable", "My balances") }
  /// My Ethereum address
  internal static var myEthereumAddress: String { L10n.tr("Localizable", "My Ethereum address") }
  /// My Solana address
  internal static var mySolanaAddress: String { L10n.tr("Localizable", "My Solana address") }
  /// My username
  internal static var myUsername: String { L10n.tr("Localizable", "My username") }
  /// name
  internal static var name: String { L10n.tr("Localizable", "name") }
  /// Name copied to clipboard
  internal static var nameCopiedToClipboard: String { L10n.tr("Localizable", "Name copied to clipboard") }
  /// name is available 👌
  internal static var nameIsAvailable👌: String { L10n.tr("Localizable", "name is available 👌 ") }
  /// Name was booked
  internal static var nameWasBooked: String { L10n.tr("Localizable", "Name was booked") }
  /// Native Solana Token
  internal static var nativeSolanaToken: String { L10n.tr("Localizable", "Native Solana Token") }
  /// Needs at least %@
  internal static func needsAtLeast(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Needs at least %@", String(describing: p1))
  }
  /// Network
  internal static var network: String { L10n.tr("Localizable", "Network") }
  /// Network changed
  internal static var networkChanged: String { L10n.tr("Localizable", "Network changed") }
  /// Network fee
  internal static var networkFee: String { L10n.tr("Localizable", "Network fee") }
  /// Never lose access to your funds
  internal static var neverLoseAccessToYourFunds: String { L10n.tr("Localizable", "Never lose access to your funds") }
  /// New PIN-code
  internal static var newPINCode: String { L10n.tr("Localizable", "New PIN-code") }
  /// New staking option available
  internal static var newStakingOptionAvailable: String { L10n.tr("Localizable", "New staking option available") }
  /// New wallet
  internal static var newWallet: String { L10n.tr("Localizable", "New wallet") }
  /// next
  internal static var next: String { L10n.tr("Localizable", "next") }
  /// Nice! Almost done
  internal static var niceAlmostDone: String { L10n.tr("Localizable", "Nice! Almost done") }
  /// No account
  internal static var noAccount: String { L10n.tr("Localizable", "No account") }
  /// No chart data available.
  internal static var noChartDataAvailable: String { L10n.tr("Localizable", "No chart data available.") }
  /// No hidden costs
  internal static var noHiddenCosts: String { L10n.tr("Localizable", "No hidden costs") }
  /// No Internet connection
  internal static var noInternetConnection: String { L10n.tr("Localizable", "No Internet connection") }
  /// No more than 15 alphanumerical latin lowercase characters and dashes
  internal static var noMoreThan15AlphanumericalLatinLowercaseCharactersAndDashes: String { L10n.tr("Localizable", "No more than 15 alphanumerical latin lowercase characters and dashes") }
  /// No routes for swapping current token pair
  internal static var noRoutesForSwappingCurrentTokenPair: String { L10n.tr("Localizable", "No routes for swapping current token pair") }
  /// no signer found
  internal static var noSignerFound: String { L10n.tr("Localizable", "no signer found") }
  /// No swap options for these tokens
  internal static var noSwapOptionsForTheseTokens: String { L10n.tr("Localizable", "No swap options for these tokens") }
  /// No transactions yet
  internal static var noTransactionsYet: String { L10n.tr("Localizable", "No transactions yet") }
  /// No wallet found
  internal static var noWalletFound: String { L10n.tr("Localizable", "No wallet found") }
  /// Nobody has access to your funds, so you need to execute the transaction cash out
  internal static var nobodyHasAccessToYourFundsSoYouNeedToExecuteTheTransactionCashOut: String { L10n.tr("Localizable", "Nobody has access to your funds, so you need to execute the transaction cash out") }
  /// Non-native account can only be closed if its balance is zero
  internal static var nonNativeAccountCanOnlyBeClosedIfItsBalanceIsZero: String { L10n.tr("Localizable", "Non-native account can only be closed if its balance is zero") }
  /// None
  internal static var `none`: String { L10n.tr("Localizable", "None") }
  /// Not available for now
  internal static var notAvailableForNow: String { L10n.tr("Localizable", "Not available for now") }
  /// Not enough %@
  internal static func notEnough(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Not enough %@", String(describing: p1))
  }
  /// Not enough %@ to pay network fee
  internal static func notEnoughToPayNetworkFee(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Not enough %@ to pay network fee", String(describing: p1))
  }
  /// Not enough balance
  internal static var notEnoughBalance: String { L10n.tr("Localizable", "Not enough balance") }
  /// Not enough funds
  internal static var notEnoughFunds: String { L10n.tr("Localizable", "Not enough funds") }
  /// Not enough output amount
  internal static var notEnoughOutputAmount: String { L10n.tr("Localizable", "Not enough output amount") }
  /// Not enough token balance
  internal static var notEnoughTokenBalance: String { L10n.tr("Localizable", "Not enough token balance") }
  /// Not enought %@
  internal static func notEnought(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Not enought %@", String(describing: p1))
  }
  /// Not Found
  internal static var notFound: String { L10n.tr("Localizable", "Not Found") }
  /// Not reserved
  internal static var notReserved: String { L10n.tr("Localizable", "Not reserved") }
  /// Not valid signature
  internal static var notValidSignature: String { L10n.tr("Localizable", "Not valid signature") }
  /// Not yet reserved
  internal static var notYetReserved: String { L10n.tr("Localizable", "Not yet reserved") }
  /// Nothing found
  internal static var nothingFound: String { L10n.tr("Localizable", "Nothing found") }
  /// Notifications
  internal static var notifications: String { L10n.tr("Localizable", "Notifications") }
  /// Ok
  internal static var ok: String { L10n.tr("Localizable", "Ok") }
  /// Okay
  internal static var okay: String { L10n.tr("Localizable", "Okay") }
  /// On the Solana network, the first 100 transactions in a day are paid by Key App
  internal static var onTheSolanaNetworkTheFirst100TransactionsInADayArePaidByKeyApp: String { L10n.tr("Localizable", "On the Solana network, the first 100 transactions in a day are paid by Key App") }
  /// one crypto for another
  internal static var oneCryptoForAnother: String { L10n.tr("Localizable", "one crypto for another") }
  /// One unified address to receive SOL or SPL Tokens
  internal static var oneUnifiedAddressToReceiveSOLOrSPLTokens: String { L10n.tr("Localizable", "One unified address to receive SOL or SPL Tokens") }
  /// only Bitcoin
  internal static var onlyBitcoin: String { L10n.tr("Localizable", "only Bitcoin") }
  /// Oops! Something happened.
  internal static var oopsSomethingHappened: String { L10n.tr("Localizable", "Oops! Something happened.") }
  /// Open settings
  internal static var openSettings: String { L10n.tr("Localizable", "Open settings") }
  /// Open your link again
  internal static var openYourLinkAgain: String { L10n.tr("Localizable", "Open your link again") }
  /// or reset it with a seed phrase
  internal static var orResetItWithASeedPhrase: String { L10n.tr("Localizable", "or reset it with a seed phrase") }
  /// Or saving into Keychain
  internal static var orSavingIntoKeychain: String { L10n.tr("Localizable", "Or saving into Keychain") }
  /// or your SOL account's address
  internal static var orYourSOLAccountSAddress: String { L10n.tr("Localizable", "or your SOL account's address") }
  /// Other tokens
  internal static var otherTokens: String { L10n.tr("Localizable", "Other tokens") }
  /// Paid by Key App
  internal static var paidByKeyApp: String { L10n.tr("Localizable", "Paid by Key App") }
  /// Parse Error
  internal static var parseError: String { L10n.tr("Localizable", "Parse Error") }
  /// passcodes do not match
  internal static var passcodesDoNotMatch: String { L10n.tr("Localizable", "passcodes do not match") }
  /// Paste
  internal static var paste: String { L10n.tr("Localizable", "Paste") }
  /// Pasted from clipboard
  internal static var pastedFromClipboard: String { L10n.tr("Localizable", "Pasted from clipboard") }
  /// Pay %@ & Continue
  internal static func payAndContinue(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Pay %@ and Continue", String(describing: p1))
  }
  /// Pay fees with
  internal static var payFeesWith: String { L10n.tr("Localizable", "Pay fees with") }
  /// Pay network fee with
  internal static var payNetworkFeeWith: String { L10n.tr("Localizable", "Pay network fee with") }
  /// Pay swap fees with
  internal static var paySwapFeesWith: String { L10n.tr("Localizable", "Pay swap fees with") }
  /// Pay the %@ fee with
  internal static func payTheFeeWith(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Pay the %@ fee with", String(describing: p1))
  }
  /// Payments
  internal static var payments: String { L10n.tr("Localizable", "Payments") }
  /// pending
  internal static var pending: String { L10n.tr("Localizable", "pending") }
  /// per
  internal static var per: String { L10n.tr("Localizable", "per") }
  /// Phone
  internal static var phone: String { L10n.tr("Localizable", "Phone") }
  /// Pick a token
  internal static var pickAToken: String { L10n.tr("Localizable", "Pick a token") }
  /// Pick Your Username
  internal static var pickYourUsername: String { L10n.tr("Localizable", "Pick Your Username") }
  /// PIN code
  internal static var pinCode: String { L10n.tr("Localizable", "PIN code") }
  /// PIN is set
  internal static var pinIsSet: String { L10n.tr("Localizable", "PIN is set") }
  /// PIN-code changed!
  internal static var pinCodeChanged: String { L10n.tr("Localizable", "PIN-code changed!") }
  /// PIN-code must have 6 digits
  internal static var pinCodeMustHave6Digits: String { L10n.tr("Localizable", "PIN-code must have 6 digits") }
  /// PIN-codes do not match
  internal static var pinCodesDoNotMatch: String { L10n.tr("Localizable", "PIN-codes do not match") }
  /// Please choose another token and try again!
  internal static var pleaseChooseAnotherTokenAndTryAgain: String { L10n.tr("Localizable", "Please choose another token and try again!") }
  /// Please choose paying with SOL
  internal static var pleaseChoosePayingWithSOL: String { L10n.tr("Localizable", "Please choose paying with SOL") }
  /// Please re-enter PIN-code
  internal static var pleaseReEnterPINCode: String { L10n.tr("Localizable", "Please re-enter PIN-code") }
  /// Please retry operation
  internal static var pleaseRetryOperation: String { L10n.tr("Localizable", "Please retry operation") }
  /// please try again later!
  internal static var pleaseTryAgainLater: String { L10n.tr("Localizable", "please try again later!") }
  /// Please wait 10 min and will ask for new OTP
  internal static var pleaseWait10MinAndWillAskForNewOTP: String { L10n.tr("Localizable", "Please wait 10 min and will ask for new OTP") }
  /// Please wait, it won't take long
  internal static var pleaseWaitItWonTTakeLong: String { L10n.tr("Localizable", "Please wait, it won't take long") }
  /// Please, send crypto to MoonPay address
  internal static var pleaseSendCryptoToMoonPayAddress: String { L10n.tr("Localizable", "Please, send crypto to MoonPay address") }
  /// popular
  internal static var popular: String { L10n.tr("Localizable", "popular") }
  /// Popular coins
  internal static var popularCoins: String { L10n.tr("Localizable", "Popular coins") }
  /// Powered by
  internal static var poweredBy: String { L10n.tr("Localizable", "Powered by") }
  /// Powered by Project Serum
  internal static var poweredByProjectSerum: String { L10n.tr("Localizable", "Powered by Project Serum") }
  /// Price
  internal static var price: String { L10n.tr("Localizable", "Price") }
  /// Prices updated
  internal static var pricesUpdated: String { L10n.tr("Localizable", "Prices updated") }
  /// Privacy Policy
  internal static var privacyPolicy: String { L10n.tr("Localizable", "Privacy Policy") }
  /// Private & secure
  internal static var privateAndSecure: String { L10n.tr("Localizable", "Private and secure") }
  /// Proceed
  internal static var proceed: String { L10n.tr("Localizable", "Proceed") }
  /// Proceed & don’t show again
  internal static var proceedDonTShowAgain: String { L10n.tr("Localizable", "Proceed & don’t show again") }
  /// Proceed without a username?
  internal static var proceedWithoutAUsername: String { L10n.tr("Localizable", "Proceed without a username?") }
  /// Processing
  internal static var processing: String { L10n.tr("Localizable", "Processing") }
  /// Processing fee
  internal static var processingFee: String { L10n.tr("Localizable", "Processing fee") }
  /// Profile
  internal static var profile: String { L10n.tr("Localizable", "Profile") }
  /// PROFILE AND SECURITY
  internal static var profileAndSecurity: String { L10n.tr("Localizable", "PROFILE AND SECURITY") }
  /// PublicKey not found
  internal static var publicKeyNotFound: String { L10n.tr("Localizable", "PublicKey not found") }
  /// Purchasing on the Moonpay’s website
  internal static var purchasingOnTheMoonpaySWebsite: String { L10n.tr("Localizable", "Purchasing on the Moonpay’s website") }
  /// Reason
  internal static var reason: String { L10n.tr("Localizable", "Reason") }
  /// Receive
  internal static var receive: String { L10n.tr("Localizable", "Receive") }
  /// Receive %@
  internal static func receive(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Receive %@", String(describing: p1))
  }
  /// Receive %@ on %@
  internal static func receiveOn(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Receive %@ on %@", String(describing: p1), String(describing: p2))
  }
  /// Receive **any token** within the Solana network even if it is not included in your wallet list
  internal static var receiveAnyTokenWithinTheSolanaNetworkEvenIfItIsNotIncludedInYourWalletList: String { L10n.tr("Localizable", "Receive any token within the Solana network even if it is not included in your wallet list") }
  /// Receive at least
  internal static var receiveAtLeast: String { L10n.tr("Localizable", "Receive at least") }
  /// Receive at least: %@ %@
  internal static func receiveAtLeast(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Receive at least: %@ %@", String(describing: p1), String(describing: p2))
  }
  /// Receive money
  internal static var receiveMoney: String { L10n.tr("Localizable", "Receive money") }
  /// Receive token
  internal static var receiveToken: String { L10n.tr("Localizable", "Receive token") }
  /// Receive token using SOL wallet's address
  internal static var receiveTokenUsingSOLWalletSAddress: String { L10n.tr("Localizable", "Receive token using SOL wallet's address") }
  /// Receive tokens
  internal static var receiveTokens: String { L10n.tr("Localizable", "Receive tokens") }
  /// Receive tokens on Ethereum and Solana
  internal static var receiveTokensOnEthereumAndSolana: String { L10n.tr("Localizable", "Receive tokens on Ethereum and Solana") }
  /// Received
  internal static var received: String { L10n.tr("Localizable", "Received") }
  /// Received %@
  internal static func received(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Received %@", String(describing: p1))
  }
  /// Received %@ renBTC
  internal static func receivedRenBTC(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Received %@ renBTC", String(describing: p1))
  }
  /// Received from
  internal static var receivedFrom: String { L10n.tr("Localizable", "Received from") }
  /// Receiving %@ renBTC
  internal static func receivingRenBTC(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Receiving %@ renBTC", String(describing: p1))
  }
  /// Receiving %@ renBTC: Pending
  internal static func receivingRenBTCPending(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Receiving %@ renBTC: Pending", String(describing: p1))
  }
  /// Receiving status
  internal static var receivingStatus: String { L10n.tr("Localizable", "Receiving status") }
  /// Receiving statuses
  internal static var receivingStatuses: String { L10n.tr("Localizable", "Receiving statuses") }
  /// Receiving via Bitcoin network
  internal static var receivingViaBitcoinNetwork: String { L10n.tr("Localizable", "Receiving via Bitcoin network") }
  /// Recently used
  internal static var recentlyUsed: String { L10n.tr("Localizable", "Recently used") }
  /// Recipient
  internal static var recipient: String { L10n.tr("Localizable", "Recipient") }
  /// Recipient gets
  internal static var recipientGets: String { L10n.tr("Localizable", "Recipient gets") }
  /// Recipient’s address
  internal static var recipientSAddress: String { L10n.tr("Localizable", "Recipient’s address") }
  /// Recovery kit
  internal static var recoveryKit: String { L10n.tr("Localizable", "Recovery kit") }
  /// Refresh
  internal static var refresh: String { L10n.tr("Localizable", "Refresh") }
  /// Refresh page
  internal static var refreshPage: String { L10n.tr("Localizable", "Refresh page") }
  /// Refresh the page or check back later
  internal static var refreshThePageOrCheckBackLater: String { L10n.tr("Localizable", "Refresh the page or check back later") }
  /// Reload
  internal static var reload: String { L10n.tr("Localizable", "Reload") }
  /// Remove from history
  internal static var removeFromHistory: String { L10n.tr("Localizable", "Remove from history") }
  /// renBTC
  internal static var renBTC: String { L10n.tr("Localizable", "renBTC") }
  /// renBTC account is required
  internal static var renBTCAccountIsRequired: String { L10n.tr("Localizable", "renBTC account is required") }
  /// Renew
  internal static var renew: String { L10n.tr("Localizable", "Renew") }
  /// Repeat new PIN-code
  internal static var repeatNewPINCode: String { L10n.tr("Localizable", "Repeat new PIN-code") }
  /// Repeat social auth
  internal static var repeatSocialAuth: String { L10n.tr("Localizable", "Repeat social auth") }
  /// Reserve username
  internal static var reserveUsername: String { L10n.tr("Localizable", "Reserve username") }
  /// Reserve your username
  internal static var reserveYourUsername: String { L10n.tr("Localizable", "Reserve your username") }
  /// Reset and try again
  internal static var resetAndTryAgain: String { L10n.tr("Localizable", "Reset and try again") }
  /// Reset it
  internal static var resetIt: String { L10n.tr("Localizable", "Reset it") }
  /// Reset PIN with a seed phrase
  internal static var resetPINWithASeedPhrase: String { L10n.tr("Localizable", "Reset PIN with a seed phrase") }
  /// Reset your PIN
  internal static var resetYourPIN: String { L10n.tr("Localizable", "Reset your PIN") }
  /// Resetting your PIN
  internal static var resettingYourPIN: String { L10n.tr("Localizable", "Resetting your PIN") }
  /// Response error
  internal static var responseError: String { L10n.tr("Localizable", "Response error") }
  /// Restore
  internal static var restore: String { L10n.tr("Localizable", "Restore") }
  /// Restore manually
  internal static var restoreManually: String { L10n.tr("Localizable", "Restore manually") }
  /// Restore using iCloud
  internal static var restoreUsingICloud: String { L10n.tr("Localizable", "Restore using iCloud") }
  /// Restore your wallet
  internal static var restoreYourWallet: String { L10n.tr("Localizable", "Restore your wallet") }
  /// Restoring wallet
  internal static var restoringWallet: String { L10n.tr("Localizable", "Restoring wallet") }
  /// Result
  internal static var result: String { L10n.tr("Localizable", "Result") }
  /// Retry
  internal static var retry: String { L10n.tr("Localizable", "Retry") }
  /// Retry after
  internal static var retryAfter: String { L10n.tr("Localizable", "Retry after") }
  /// Review & confirm
  internal static var reviewAndConfirm: String { L10n.tr("Localizable", "Review and confirm") }
  /// Russian Ruble
  internal static var russianRuble: String { L10n.tr("Localizable", "Russian Ruble") }
  /// Save
  internal static var save: String { L10n.tr("Localizable", "Save") }
  /// Save & Continue
  internal static var saveContinue: String { L10n.tr("Localizable", "Save & Continue") }
  /// Save to iCloud
  internal static var saveToICloud: String { L10n.tr("Localizable", "Save to iCloud") }
  /// save to Keychain
  internal static var saveToKeychain: String { L10n.tr("Localizable", "save to Keychain") }
  /// Saved to iCloud
  internal static var savedToICloud: String { L10n.tr("Localizable", "Saved to iCloud") }
  /// Saved to Keychain
  internal static var savedToKeychain: String { L10n.tr("Localizable", "Saved to Keychain") }
  /// Saved to photo library
  internal static var savedToPhotoLibrary: String { L10n.tr("Localizable", "Saved to photo library") }
  /// Saving to iCloud
  internal static var savingToICloud: String { L10n.tr("Localizable", "Saving to iCloud") }
  /// Saving to Keychain
  internal static var savingToKeychain: String { L10n.tr("Localizable", "Saving to Keychain") }
  /// Savings
  internal static var savings: String { L10n.tr("Localizable", "Savings") }
  /// Scan or copy QR code
  internal static var scanOrCopyQRCode: String { L10n.tr("Localizable", "Scan or copy QR code") }
  /// Scan QR
  internal static var scanQR: String { L10n.tr("Localizable", "Scan QR") }
  /// Scan QR Code
  internal static var scanQRCode: String { L10n.tr("Localizable", "Scan QR Code") }
  /// Scanning QrCode not supported
  internal static var scanningQrCodeNotSupported: String { L10n.tr("Localizable", "Scanning QrCode not supported") }
  /// Search
  internal static var search: String { L10n.tr("Localizable", "Search") }
  /// Search token
  internal static var searchToken: String { L10n.tr("Localizable", "Search token") }
  /// seconds
  internal static var seconds: String { L10n.tr("Localizable", "seconds") }
  /// Secure non-custodial bank of future
  internal static var secureNonCustodialBankOfFuture: String { L10n.tr("Localizable", "Secure non-custodial bank of future") }
  /// Secure your wallet
  internal static var secureYourWallet: String { L10n.tr("Localizable", "Secure your wallet") }
  /// Securing key
  internal static var securingKey: String { L10n.tr("Localizable", "Securing key") }
  /// Security
  internal static var security: String { L10n.tr("Localizable", "Security") }
  /// Security & Network
  internal static var securityNetwork: String { L10n.tr("Localizable", "Security & Network") }
  /// Security & privacy
  internal static var securityAndPrivacy: String { L10n.tr("Localizable", "Security and privacy") }
  /// security key
  internal static var securityKey: String { L10n.tr("Localizable", "security key") }
  /// Seed phrase
  internal static var seedPhrase: String { L10n.tr("Localizable", "Seed phrase") }
  /// Seed phrase details
  internal static var seedPhraseDetails: String { L10n.tr("Localizable", "Seed phrase details") }
  /// Seed phrase must have 12 or 24 words
  internal static var seedPhraseMustHave12Or24Words: String { L10n.tr("Localizable", "Seed phrase must have 12 or 24 words") }
  /// Seed phrase must have at least 12 words
  internal static var seedPhraseMustHaveAtLeast12Words: String { L10n.tr("Localizable", "Seed phrase must have at least 12 words") }
  /// SELECT
  internal static var select: String { L10n.tr("Localizable", "SELECT") }
  /// Select currency
  internal static var selectCurrency: String { L10n.tr("Localizable", "Select currency") }
  /// Select Derivable Path
  internal static var selectDerivablePath: String { L10n.tr("Localizable", "Select Derivable Path") }
  /// Select the first token
  internal static var selectTheFirstToken: String { L10n.tr("Localizable", "Select the first token") }
  /// Select the second token
  internal static var selectTheSecondToken: String { L10n.tr("Localizable", "Select the second token") }
  /// Select token
  internal static var selectToken: String { L10n.tr("Localizable", "Select token") }
  /// Select token to pay fees
  internal static var selectTokenToPayFees: String { L10n.tr("Localizable", "Select token to pay fees") }
  /// Select wallet
  internal static var selectWallet: String { L10n.tr("Localizable", "Select wallet") }
  /// Select word #%@
  internal static func selectWord(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Select word #%@", String(describing: p1))
  }
  /// Select your country
  internal static var selectYourCountry: String { L10n.tr("Localizable", "Select your country") }
  /// Sell %@
  internal static func sell(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Sell %@", String(describing: p1))
  }
  /// Sell all
  internal static var sellAll: String { L10n.tr("Localizable", "Sell all") }
  /// Send
  internal static var send: String { L10n.tr("Localizable", "Send") }
  /// Send %@ %@
  internal static func send(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Send %@ %@", String(describing: p1), String(describing: p2))
  }
  /// Send %@ to your Ethereum address
  internal static func sendToYourEthereumAddress(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Send %@ to your Ethereum address", String(describing: p1))
  }
  /// Send coins
  internal static var sendCoins: String { L10n.tr("Localizable", "Send coins") }
  /// Send crypto in the Bitcoin and Solana\nnetwork instantly and without fees
  internal static var sendCryptoInTheBitcoinAndSolanaNetworkInstantlyAndWithoutFees: String { L10n.tr("Localizable", "Send crypto in the Bitcoin and Solana\nnetwork instantly and without fees") }
  /// Send crypto in the Solana network\ninstantly and without fees
  internal static var sendCryptoInTheSolanaNetworkInstantlyAndWithoutFees: String { L10n.tr("Localizable", "Send crypto in the Solana network\ninstantly and without fees") }
  /// Send crypto via link
  internal static var sendCryptoViaLink: String { L10n.tr("Localizable", "Send crypto via link") }
  /// Send for free
  internal static var sendForFree: String { L10n.tr("Localizable", "Send for free") }
  /// Send money via link
  internal static var sendMoneyViaLink: String { L10n.tr("Localizable", "Send money via link") }
  /// Send Now
  internal static var sendNow: String { L10n.tr("Localizable", "Send Now") }
  /// Send SOL or any SPL Tokens on one address
  internal static var sendSOLOrAnySPLTokensOnOneAddress: String { L10n.tr("Localizable", "Send SOL or any SPL Tokens on one address") }
  /// Send to
  internal static var sendTo: String { L10n.tr("Localizable", "Send to") }
  /// Send to your wallet
  internal static var sendToYourWallet: String { L10n.tr("Localizable", "Send to your wallet") }
  /// Send tokens
  internal static var sendTokens: String { L10n.tr("Localizable", "Send tokens") }
  /// Send via link
  internal static var sendViaLink: String { L10n.tr("Localizable", "Send via link") }
  /// Sender’s\naddress
  internal static var senderSAddress: String { L10n.tr("Localizable", "Sender’s address") }
  /// Sending
  internal static var sending: String { L10n.tr("Localizable", "Sending") }
  /// Sending token...
  internal static var sendingToken: String { L10n.tr("Localizable", "Sending token...") }
  /// Sending tokens has\nnever been EASIER
  internal static var sendingTokensHasNeverBeenEASIER: String { L10n.tr("Localizable", "Sending tokens has\nnever been EASIER") }
  /// Sending via link
  internal static var sendingViaLink: String { L10n.tr("Localizable", "Sending via link") }
  /// Sent
  internal static var sent: String { L10n.tr("Localizable", "Sent") }
  /// Sent to
  internal static var sentTo: String { L10n.tr("Localizable", "Sent to") }
  /// Sent via one-time link
  internal static var sentViaOneTimeLink: String { L10n.tr("Localizable", "Sent via one-time link") }
  /// Serum order creation (paid once per pair)
  internal static var serumOrderCreationPaidOncePerPair: String { L10n.tr("Localizable", "Serum order creation (paid once per pair)") }
  /// service is next step
  internal static var serviceIsNextStep: String { L10n.tr("Localizable", "service is next step") }
  /// Set up
  internal static var setUp: String { L10n.tr("Localizable", "Set up") }
  /// Set up a new PIN
  internal static var setUpANewPIN: String { L10n.tr("Localizable", "Set up a new PIN") }
  /// Set up a new wallet PIN
  internal static var setUpANewWalletPIN: String { L10n.tr("Localizable", "Set up a new wallet PIN") }
  /// Set up a wallet PIN
  internal static var setUpAWalletPIN: String { L10n.tr("Localizable", "Set up a wallet PIN") }
  /// Settings
  internal static var settings: String { L10n.tr("Localizable", "Settings") }
  /// Share
  internal static var share: String { L10n.tr("Localizable", "Share") }
  /// Share your link to send money
  internal static var shareYourLinkToSendMoney: String { L10n.tr("Localizable", "Share your link to send money") }
  /// Share your Solana network address
  internal static var shareYourSolanaNetworkAddress: String { L10n.tr("Localizable", "Share your Solana network address") }
  /// Show
  internal static var show: String { L10n.tr("Localizable", "Show") }
  /// Show address
  internal static var showAddress: String { L10n.tr("Localizable", "Show address") }
  /// Show address detail
  internal static var showAddressDetail: String { L10n.tr("Localizable", "Show address detail") }
  /// Show deposit
  internal static var showDeposit: String { L10n.tr("Localizable", "Show deposit") }
  /// Show deposit (%@)
  internal static func showDeposit(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Show deposit (%@)", String(describing: p1))
  }
  /// Show deposits
  internal static var showDeposits: String { L10n.tr("Localizable", "Show deposits") }
  /// Show details
  internal static var showDetails: String { L10n.tr("Localizable", "Show details") }
  /// Show direct and mint addresses
  internal static var showDirectAndMintAddresses: String { L10n.tr("Localizable", "Show direct and mint addresses") }
  /// Show fees
  internal static var showFees: String { L10n.tr("Localizable", "Show fees") }
  /// Show my private key
  internal static var showMyPrivateKey: String { L10n.tr("Localizable", "Show my private key") }
  /// Show my seed phrase
  internal static var showMySeedPhrase: String { L10n.tr("Localizable", "Show my seed phrase") }
  /// Show seed phrase
  internal static var showSeedPhrase: String { L10n.tr("Localizable", "Show seed phrase") }
  /// Show swap details
  internal static var showSwapDetails: String { L10n.tr("Localizable", "Show swap details") }
  /// Show transaction details
  internal static var showTransactionDetails: String { L10n.tr("Localizable", "Show transaction details") }
  /// Show wallet address
  internal static var showWalletAddress: String { L10n.tr("Localizable", "Show wallet address") }
  /// Show your security key
  internal static var showYourSecurityKey: String { L10n.tr("Localizable", "Show your security key") }
  /// Showing my address for
  internal static var showingMyAddressFor: String { L10n.tr("Localizable", "Showing my address for") }
  /// Signature
  internal static var signature: String { L10n.tr("Localizable", "Signature") }
  /// Signer error
  internal static var signerError: String { L10n.tr("Localizable", "Signer error") }
  /// Simple decentralized finance for everyone
  internal static var simpleDecentralizedFinanceForEveryone: String { L10n.tr("Localizable", "Simple decentralized finance for everyone") }
  /// Simple finance for everyone
  internal static var simpleFinanceForEveryone: String { L10n.tr("Localizable", "Simple finance for everyone") }
  /// skip
  internal static var skip: String { L10n.tr("Localizable", "skip") }
  /// Slide to deposit
  internal static var slideToDeposit: String { L10n.tr("Localizable", "Slide to deposit") }
  /// Slide to scan
  internal static var slideToScan: String { L10n.tr("Localizable", "Slide to scan") }
  /// Slide to withdraw
  internal static var slideToWithdraw: String { L10n.tr("Localizable", "Slide to withdraw") }
  /// Slippage
  internal static var slippage: String { L10n.tr("Localizable", "Slippage") }
  /// Slippage can occur at any time, but it is most prevalent during periods of %@
  internal static func slippageCanOccurAtAnyTimeButItIsMostPrevalentDuringPeriodsOf(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Slippage can occur at any time, but it is most prevalent during periods of %@", String(describing: p1))
  }
  /// Slippage error
  internal static var slippageError: String { L10n.tr("Localizable", "Slippage error") }
  /// Slippage exceeds maximum
  internal static var slippageExceedsMaximum: String { L10n.tr("Localizable", "Slippage exceeds maximum") }
  /// Slippage isn't valid
  internal static var slippageIsnTValid: String { L10n.tr("Localizable", "Slippage isn't valid") }
  /// Slippage settings
  internal static var slippageSettings: String { L10n.tr("Localizable", "Slippage settings") }
  /// Slippage tolerance %@
  internal static func slippageTolerance(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Slippage tolerance %@", String(describing: p1))
  }
  /// So, let’s breathe
  internal static var soLetSBreathe: String { L10n.tr("Localizable", "So, let’s breathe") }
  /// Socket returns an error
  internal static var socketReturnsAnError: String { L10n.tr("Localizable", "Socket returns an error") }
  /// SOL and SPL Tokens
  internal static var solAndSPLTokens: String { L10n.tr("Localizable", "SOL and SPL Tokens") }
  /// SOL Price
  internal static var solPrice: String { L10n.tr("Localizable", "SOL Price") }
  /// SOL purchase cost
  internal static var solPurchaseCost: String { L10n.tr("Localizable", "SOL purchase cost") }
  /// Solana
  internal static var solana: String { L10n.tr("Localizable", "Solana") }
  /// Solana has some problems
  internal static var solanaHasSomeProblems: String { L10n.tr("Localizable", "Solana has some problems") }
  /// Solana Name Service doesn't respond.
  internal static var solanaNameServiceDoesnTRespond: String { L10n.tr("Localizable", "Solana Name Service doesn't respond.") }
  /// Solana program error
  internal static var solanaProgramError: String { L10n.tr("Localizable", "Solana program error") }
  /// Solana RPC client error
  internal static var solanaRPCClientError: String { L10n.tr("Localizable", "Solana RPC client error") }
  /// Solend is one of the most scalable, fastest and lowest fee DeFi lending protocol, that allows you to earn interest on your assets.
  internal static var solendIsOneOfTheMostScalableFastestAndLowestFeeDeFiLendingProtocolThatAllowsYouToEarnInterestOnYourAssets: String { L10n.tr("Localizable", "Solend is one of the most scalable, fastest and lowest fee DeFi lending protocol, that allows you to earn interest on your assets.") }
  /// Some parameters are missing
  internal static var someParametersAreMissing: String { L10n.tr("Localizable", "Some parameters are missing") }
  /// Something went wrong
  internal static var somethingWentWrong: String { L10n.tr("Localizable", "Something went wrong") }
  /// Something went wrong!\nPlease try again later
  internal static var somethingWentWrongPleaseTryAgainLater: String { L10n.tr("Localizable", "Something went wrong!\nPlease try again later") }
  /// Sorry
  internal static var sorry: String { L10n.tr("Localizable", "Sorry") }
  /// Sorry, we don't know such a country
  internal static var sorryWeDonTKnowSuchACountry: String { L10n.tr("Localizable", "Sorry, we don't know such a country") }
  /// Sorry, we don't know that country
  internal static var sorryWeDonTKnowThatCountry: String { L10n.tr("Localizable", "Sorry, we don't know that country") }
  /// Sorry, we don’t know a such country
  internal static var sorryWeDonTKnowASuchCountry: String { L10n.tr("Localizable", "Sorry, we don’t know a such country") }
  /// Source account is not valid
  internal static var sourceAccountIsNotValid: String { L10n.tr("Localizable", "Source account is not valid") }
  /// Spend
  internal static var spend: String { L10n.tr("Localizable", "Spend") }
  /// Spent
  internal static var spent: String { L10n.tr("Localizable", "Spent") }
  /// Stake
  internal static var stake: String { L10n.tr("Localizable", "Stake") }
  /// Stake signature
  internal static var stakeSignature: String { L10n.tr("Localizable", "Stake signature") }
  /// Stake your tokens & get rewards every day
  internal static var stakeYourTokensAndGetRewardsEveryDay: String { L10n.tr("Localizable", "Stake your tokens and get rewards every day") }
  /// Starting screen
  internal static var startingScreen: String { L10n.tr("Localizable", "Starting screen") }
  /// Status
  internal static var status: String { L10n.tr("Localizable", "Status") }
  /// Statuses received
  internal static var statusesReceived: String { L10n.tr("Localizable", "Statuses received") }
  /// Statuses received (%@)
  internal static func statusesReceived(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Statuses received (%@)", String(describing: p1))
  }
  /// Stay
  internal static var stay: String { L10n.tr("Localizable", "Stay") }
  /// Step %@ of %@
  internal static func stepOf(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Step %@ of %@", String(describing: p1), String(describing: p2))
  }
  /// Submitted to RenVM
  internal static var submittedToRenVM: String { L10n.tr("Localizable", "Submitted to RenVM") }
  /// Submitting to RenVM
  internal static var submittingToRenVM: String { L10n.tr("Localizable", "Submitting to RenVM") }
  /// Success
  internal static var success: String { L10n.tr("Localizable", "Success") }
  /// Successfully changed PIN-code
  internal static var successfullyChangedPINCode: String { L10n.tr("Localizable", "Successfully changed PIN-code") }
  /// Successfully minted %@ renBTC!
  internal static func successfullyMintedRenBTC(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Successfully minted %@ renBTC!", String(describing: p1))
  }
  /// Suggest ways to improve Key App
  internal static var suggestWaysToImproveKeyApp: String { L10n.tr("Localizable", "Suggest ways to improve Key App") }
  /// Superhero protection
  internal static var superheroProtection: String { L10n.tr("Localizable", "Superhero protection") }
  /// Support
  internal static var support: String { L10n.tr("Localizable", "Support") }
  /// Supported tokens
  internal static var supportedTokens: String { L10n.tr("Localizable", "Supported tokens") }
  /// Swap
  internal static var swap: String { L10n.tr("Localizable", "Swap") }
  /// Swap %@ → %@
  internal static func swap(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Swap %@ → %@", String(describing: p1), String(describing: p2))
  }
  /// Swap details
  internal static var swapDetails: String { L10n.tr("Localizable", "Swap details") }
  /// Swap fees
  internal static var swapFees: String { L10n.tr("Localizable", "Swap fees") }
  /// Swap instruction exceeds desired slippage limit
  internal static var swapInstructionExceedsDesiredSlippageLimit: String { L10n.tr("Localizable", "Swap instruction exceeds desired slippage limit") }
  /// Swap now
  internal static var swapNow: String { L10n.tr("Localizable", "Swap now") }
  /// Swap settings
  internal static var swapSettings: String { L10n.tr("Localizable", "Swap settings") }
  /// Swap with crypto
  internal static var swapWithCrypto: String { L10n.tr("Localizable", "Swap with crypto") }
  /// Swap your cryptocurrencies\nto SOL to cash out
  internal static var swapYourCryptocurrenciesToSOLToCashOut: String { L10n.tr("Localizable", "Swap your cryptocurrencies\nto SOL to cash out") }
  /// Swapping
  internal static var swapping: String { L10n.tr("Localizable", "Swapping") }
  /// Swapping from %@ to %@ is currently unsupported
  internal static func swappingFromToIsCurrentlyUnsupported(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Swapping from %@ to %@ is currently unsupported", String(describing: p1), String(describing: p2))
  }
  /// Swapping is currently unavailable
  internal static var swappingIsCurrentlyUnavailable: String { L10n.tr("Localizable", "Swapping is currently unavailable") }
  /// Swapping pools not found
  internal static var swappingPoolsNotFound: String { L10n.tr("Localizable", "Swapping pools not found") }
  /// Swapping Through
  internal static var swappingThrough: String { L10n.tr("Localizable", "Swapping Through") }
  /// Switch language?
  internal static var switchLanguage: String { L10n.tr("Localizable", "Switch language?") }
  /// Switch network?
  internal static var switchNetwork: String { L10n.tr("Localizable", "Switch network?") }
  /// Switch to %@
  internal static func switchTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Switch to %@", String(describing: p1))
  }
  /// Switch to another token
  internal static var switchToAnotherToken: String { L10n.tr("Localizable", "Switch to another token") }
  /// Switching network...
  internal static var switchingNetwork: String { L10n.tr("Localizable", "Switching network...") }
  /// Switching to
  internal static var switchingTo: String { L10n.tr("Localizable", "Switching to") }
  /// System
  internal static var system: String { L10n.tr("Localizable", "System") }
  /// System error
  internal static var systemError: String { L10n.tr("Localizable", "System error") }
  /// Tap and hold to copy
  internal static var tapAndHoldToCopy: String { L10n.tr("Localizable", "Tap and hold to copy") }
  /// Tap button to retry!
  internal static var tapButtonToRetry: String { L10n.tr("Localizable", "Tap button to retry!") }
  /// Tap for details
  internal static var tapForDetails: String { L10n.tr("Localizable", "Tap for details") }
  /// Tap here to retry
  internal static var tapHereToRetry: String { L10n.tr("Localizable", "Tap here to retry") }
  /// tap refresh button to retry
  internal static var tapRefreshButtonToRetry: String { L10n.tr("Localizable", "tap refresh button to retry") }
  /// Tap to switch to %@
  internal static func tapToSwitchTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Tap to switch to %@", String(describing: p1))
  }
  /// Tap to try again
  internal static var tapToTryAgain: String { L10n.tr("Localizable", "Tap to try again") }
  /// Tap to view in explorer
  internal static var tapToViewInExplorer: String { L10n.tr("Localizable", "Tap to view in explorer") }
  /// Terms and conditions
  internal static var termsAndConditions: String { L10n.tr("Localizable", "Terms and conditions") }
  /// Terms of Service
  internal static var termsOfService: String { L10n.tr("Localizable", "Terms of Service") }
  /// Terms of Use
  internal static var termsOfUse: String { L10n.tr("Localizable", "Terms of Use") }
  /// Terms of Use and Privacy Policy
  internal static var termsOfUseAndPrivacyPolicy: String { L10n.tr("Localizable", "Terms of Use and Privacy Policy") }
  /// The %@ fee was reserved, so you wouldn't pay it again the next time you created a transaction of the same type.
  internal static func theFeeWasReservedSoYouWouldnTPayItAgainTheNextTimeYouCreatedATransactionOfTheSameType(_ p1: Any) -> String {
    return L10n.tr("Localizable", "The %@ fee was reserved, so you wouldn't pay it again the next time you created a transaction of the same type.", String(describing: p1))
  }
  /// The address %@ is recognized
  internal static func theAddressIsRecognized(_ p1: Any) -> String {
    return L10n.tr("Localizable", "The address %@ is recognized", String(describing: p1))
  }
  /// The address is not valid
  internal static var theAddressIsNotValid: String { L10n.tr("Localizable", "The address is not valid") }
  /// The address was copied to clipboard
  internal static var theAddressWasCopiedToClipboard: String { L10n.tr("Localizable", "The address was copied to clipboard") }
  /// The bank has not seen the given %@ or the transaction is too old and the %@ has been discarded.
  internal static func theBankHasNotSeenTheGivenOrTheTransactionIsTooOldAndTheHasBeenDiscarded(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "The bank has not seen the given %@ or the transaction is too old and the %@ has been discarded.", String(describing: p1), String(describing: p2))
  }
  /// The code from SMS
  internal static var theCodeFromSMS: String { L10n.tr("Localizable", "The code from SMS") }
  /// The data will be cleared without the possibility of recovery
  internal static var theDataWillBeClearedWithoutThePossibilityOfRecovery: String { L10n.tr("Localizable", "The data will be cleared without the possibility of recovery") }
  /// The definition
  internal static var theDefinition: String { L10n.tr("Localizable", "The definition") }
  /// The device was successfully changed
  internal static var theDeviceWasSuccessfullyChanged: String { L10n.tr("Localizable", "The device was successfully changed") }
  /// The fee calculation failed due to overflow, underflow or unexpected 0
  internal static var theFeeCalculationFailedDueToOverflowUnderflowOrUnexpected0: String { L10n.tr("Localizable", "The fee calculation failed due to overflow, underflow or unexpected 0") }
  /// The fee is more than the amount sent
  internal static var theFeeIsMoreThanTheAmountSent: String { L10n.tr("Localizable", "The fee is more than the amount sent") }
  /// The fee is more than the defined slippage %@ due to one-time account creation fee by Solana blockchain
  internal static func theFeeIsMoreThanTheDefinedSlippageDueToOneTimeAccountCreationFeeBySolanaBlockchain(_ p1: Any) -> String {
    return L10n.tr("Localizable", "The fee is more than the defined slippage %@ due to one-time account creation fee by Solana blockchain", String(describing: p1))
  }
  /// The fees are bigger than the transaction amount
  internal static var theFeesAreBiggerThanTheTransactionAmount: String { L10n.tr("Localizable", "The fees are bigger than the transaction amount") }
  /// The funds have been deposited\nsuccessfully
  internal static var theFundsHaveBeenDepositedSuccessfully: String { L10n.tr("Localizable", "The funds have been deposited\nsuccessfully") }
  /// The funds have been withdrawn\nsuccessfully
  internal static var theFundsHaveBeenWithdrawnSuccessfully: String { L10n.tr("Localizable", "The funds have been withdrawn\nsuccessfully") }
  /// The funds were sent to your\nbank account
  internal static var theFundsWereSentToYourBankAccount: String { L10n.tr("Localizable", "The funds were sent to your\nbank account") }
  /// The future of non-custodial banking: the easy way to buy, sell and hold cryptos
  internal static var theFutureOfNonCustodialBankingTheEasyWayToBuySellAndHoldCryptos: String { L10n.tr("Localizable", "The future of non-custodial banking: the easy way to buy, sell and hold cryptos") }
  /// The last one:
  internal static var theLastOne: String { L10n.tr("Localizable", "The last one: ") }
  /// The link is already claimed
  internal static var theLinkIsAlreadyClaimed: String { L10n.tr("Localizable", "The link is already claimed") }
  /// The link is ready!\nReceiver will be able to claim funds
  internal static var theLinkIsReadyReceiverWillBeAbleToClaimFunds: String { L10n.tr("Localizable", "The link is ready!\nReceiver will be able to claim funds") }
  /// The list is empty
  internal static var theListIsEmpty: String { L10n.tr("Localizable", "The list is empty") }
  /// The maximum amount is %@ %@
  internal static func theMaximumAmountIs(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "The maximum amount is %@ %@", String(describing: p1), String(describing: p2))
  }
  /// The maximum value is calculated by subtracting the transaction fee from your balance.
  internal static var theMaximumValueIsCalculatedBySubtractingTheTransactionFeeFromYourBalance: String { L10n.tr("Localizable", "The maximum value is calculated by subtracting the transaction fee from your balance.") }
  /// The minimum amount is %@ %@
  internal static func theMinimumAmountIs(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "The minimum amount is %@ %@", String(describing: p1), String(describing: p2))
  }
  /// The name is not available
  internal static var theNameIsNotAvailable: String { L10n.tr("Localizable", "The name is not available") }
  /// The name service is experiencing some issues, please try again later.
  internal static var theNameServiceIsExperiencingSomeIssuesPleaseTryAgainLater: String { L10n.tr("Localizable", "The name service is experiencing some issues, please try again later.") }
  /// The phrases you has entered is not correct
  internal static var thePhrasesYouHasEnteredIsNotCorrect: String { L10n.tr("Localizable", "The phrases you has entered is not correct") }
  /// The price slippage was set at %@
  internal static func thePriceSlippageWasSetAt(_ p1: Any) -> String {
    return L10n.tr("Localizable", "The price slippage was set at %@", String(describing: p1))
  }
  /// The slippage could be
  internal static var theSlippageCouldBe: String { L10n.tr("Localizable", "The slippage could be") }
  /// The swap is being processed
  internal static var theSwapIsBeingProcessed: String { L10n.tr("Localizable", "The swap is being processed") }
  /// The transaction failed due to a blockchain error
  internal static var theTransactionFailedDueToABlockchainError: String { L10n.tr("Localizable", "The transaction failed due to a blockchain error") }
  /// The transaction has been confirmed in Solana network, but you have to track it also on Bitcoin network
  internal static var theTransactionHasBeenConfirmedInSolanaNetworkButYouHaveToTrackItAlsoOnBitcoinNetwork: String { L10n.tr("Localizable", "The transaction has been confirmed in Solana network, but you have to track it also on Bitcoin network") }
  /// The transaction has been rejected
  internal static var theTransactionHasBeenRejected: String { L10n.tr("Localizable", "The transaction has been rejected") }
  /// The transaction has been successfully completed
  internal static var theTransactionHasBeenSuccessfullyCompleted: String { L10n.tr("Localizable", "The transaction has been successfully completed") }
  /// The transaction has been successfully completed 🤟
  internal static var theTransactionHasBeenSuccessfullyCompleted🤟: String { L10n.tr("Localizable", "The transaction has been successfully completed 🤟") }
  /// The transaction is being processed
  internal static var theTransactionIsBeingProcessed: String { L10n.tr("Localizable", "The transaction is being processed") }
  /// The transaction was rejected by the Solana blockchain
  internal static var theTransactionWasRejectedByTheSolanaBlockchain: String { L10n.tr("Localizable", "The transaction was rejected by the Solana blockchain") }
  /// The transaction will be completed in a few seconds
  internal static var theTransactionWillBeCompletedInAFewSeconds: String { L10n.tr("Localizable", "The transaction will be completed in a few seconds") }
  /// The username %@ is not available
  internal static func theUsernameIsNotAvailable(_ p1: Any) -> String {
    return L10n.tr("Localizable", "The username %@ is not available", String(describing: p1))
  }
  /// The wallet address is not valid, it must be a %@ wallet address
  internal static func theWalletAddressIsNotValidItMustBeAWalletAddress(_ p1: Any) -> String {
    return L10n.tr("Localizable", "The wallet address is not valid, it must be a %@ wallet address", String(describing: p1))
  }
  /// There are %@ free transactions left for today
  internal static func thereAreFreeTransactionsLeftForToday(_ p1: Any) -> String {
    return L10n.tr("Localizable", "There are %@ free transactions left for today", String(describing: p1))
  }
  /// There is an error occured, please try typing name again.
  internal static var thereIsAnErrorOccuredPleaseTryTypingNameAgain: String { L10n.tr("Localizable", "There is an error occured, please try typing name again.") }
  /// There is an error occurred, please try again
  internal static var thereIsAnErrorOccurredPleaseTryAgain: String { L10n.tr("Localizable", "There is an error occurred, please try again") }
  /// There is no %@ in your wallet to sell
  internal static func thereIsNoInYourWalletToSell(_ p1: Any) -> String {
    return L10n.tr("Localizable", "There is no %@ in your wallet to sell", String(describing: p1))
  }
  /// There is no %@ wallet in your account
  internal static func thereIsNoWalletInYourAccount(_ p1: Any) -> String {
    return L10n.tr("Localizable", "There is no %@ wallet in your account", String(describing: p1))
  }
  /// There is nothing in here!
  internal static var thereIsNothingInHere: String { L10n.tr("Localizable", "There is nothing in here!") }
  /// There is something wrong with your camera!\nPlease try again later!
  internal static var thereIsSomethingWrongWithYourCameraPleaseTryAgainLater: String { L10n.tr("Localizable", "There is something wrong with your camera!\nPlease try again later!") }
  /// There was a problem depositing funds
  internal static var thereWasAProblemDepositingFunds: String { L10n.tr("Localizable", "There was a problem depositing funds") }
  /// There was a problem with the swap, your funds were refunded
  internal static var thereWasAProblemWithTheSwapYourFundsWereRefunded: String { L10n.tr("Localizable", "There was a problem with the swap, your funds were refunded") }
  /// There was a problem withdrawing funds
  internal static var thereWasAProblemWithdrawingFunds: String { L10n.tr("Localizable", "There was a problem withdrawing funds") }
  /// There would be no additional costs
  internal static var thereWouldBeNoAdditionalCosts: String { L10n.tr("Localizable", "There would be no additional costs") }
  /// There’s no address like this
  internal static var thereSNoAddressLikeThis: String { L10n.tr("Localizable", "There’s no address like this") }
  /// These words don’t match
  internal static var theseWordsDonTMatch: String { L10n.tr("Localizable", "These words don’t match") }
  /// This address doesn’t have an account for this token
  internal static var thisAddressDoesnTHaveAnAccountForThisToken: String { L10n.tr("Localizable", "This address doesn’t have an account for this token") }
  /// This address has no funds
  internal static var thisAddressHasNoFunds: String { L10n.tr("Localizable", "This address has no funds") }
  /// This device
  internal static var thisDevice: String { L10n.tr("Localizable", "This device") }
  /// This is an easy way to send and receive cryptocurrencies in Key App
  internal static var thisIsAnEasyWayToSendAndReceiveCryptocurrenciesInKeyApp: String { L10n.tr("Localizable", "This is an easy way to send and receive cryptocurrencies in Key App") }
  /// This is required for the app to save generated QR codes or back up of your seed phrases to your photo library.
  internal static var thisIsRequiredForTheAppToSaveGeneratedQRCodesOrBackUpOfYourSeedPhrasesToYourPhotoLibrary: String { L10n.tr("Localizable", "This is required for the app to save generated QR codes or back up of your seed phrases to your photo library.") }
  /// This link is broken
  internal static var thisLinkIsBroken: String { L10n.tr("Localizable", "This link is broken") }
  /// This trading pair is not supported
  internal static var thisTradingPairIsNotSupported: String { L10n.tr("Localizable", "This trading pair is not supported") }
  /// This transaction has already been processed
  internal static var thisTransactionHasAlreadyBeenProcessed: String { L10n.tr("Localizable", "This transaction has already been processed") }
  /// This username is not associated with anyone
  internal static var thisUsernameIsNotAssociatedWithAnyone: String { L10n.tr("Localizable", "This username is not associated with anyone") }
  /// This value is calculated by subtracting the transaction fee from your balance.
  internal static var thisValueIsCalculatedBySubtractingTheTransactionFeeFromYourBalance: String { L10n.tr("Localizable", "This value is calculated by subtracting the transaction fee from your balance.") }
  /// To
  internal static var to: String { L10n.tr("Localizable", "To") }
  /// To %@
  internal static func to(_ p1: Any) -> String {
    return L10n.tr("Localizable", "To %@", String(describing: p1))
  }
  /// To access your account from another device, you need to use any 2 factors from the list below
  internal static var toAccessYourAccountFromAnotherDeviceYouNeedToUseAny2FactorsFromTheListBelow: String { L10n.tr("Localizable", "To access your account from another device, you need to use any 2 factors from the list below") }
  /// To continue, paste or scan the address (Solana or Bitcoin) or type a username
  internal static var toContinuePasteOrScanTheAddressSolanaOrBitcoinOrTypeAUsername: String { L10n.tr("Localizable", "To continue, paste or scan the address (Solana or Bitcoin) or type a username") }
  /// To continue, paste or scan the address or type a username
  internal static var toContinuePasteOrScanTheAddressOrTypeAUsername: String { L10n.tr("Localizable", "To continue, paste or scan the address or type a username") }
  /// To make a transfer to %@ you have to swap %@ to %@
  internal static func toMakeATransferToYouHaveToSwapTo(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "To make a transfer to %@ you have to swap %@ to %@", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// To recover your wallet enter your security key's 12 or 24 words separated by single spaces in the correct order
  internal static var toRecoverYourWalletEnterYourSecurityKeyS12Or24WordsSeparatedBySingleSpacesInTheCorrectOrder: String { L10n.tr("Localizable", "To recover your wallet enter your security key's 12 or 24 words separated by single spaces in the correct order") }
  /// To see %@ wallet address, you must add this token to your token list
  internal static func toSeeWalletAddressYouMustAddThisTokenToYourTokenList(_ p1: Any) -> String {
    return L10n.tr("Localizable", "To see %@ wallet address, you must add this token to your token list", String(describing: p1))
  }
  /// To send %@ to Ethereum network you have to swap it to %@
  internal static func toSendToEthereumNetworkYouHaveToSwapItTo(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "To send %@ to Ethereum network you have to swap it to %@", String(describing: p1), String(describing: p2))
  }
  /// to username or address
  internal static var toUsernameOrAddress: String { L10n.tr("Localizable", "to username or address") }
  /// To your bank account
  internal static var toYourBankAccount: String { L10n.tr("Localizable", "To your bank account") }
  /// Today
  internal static var today: String { L10n.tr("Localizable", "Today") }
  /// token account
  internal static var tokenAccount: String { L10n.tr("Localizable", "token account") }
  /// Token account not found
  internal static var tokenAccountNotFound: String { L10n.tr("Localizable", "Token account not found") }
  /// Token account should be zero
  internal static var tokenAccountShouldBeZero: String { L10n.tr("Localizable", "Token account should be zero") }
  /// Token balance must be empty
  internal static var tokenBalanceMustBeEmpty: String { L10n.tr("Localizable", "Token balance must be empty") }
  /// Token mint mismatch
  internal static var tokenMintMismatch: String { L10n.tr("Localizable", "Token mint mismatch") }
  /// Token sent!
  internal static var tokenSent: String { L10n.tr("Localizable", "Token sent!") }
  /// Token to deposit
  internal static var tokenToDeposit: String { L10n.tr("Localizable", "Token to deposit") }
  /// Token to withdraw
  internal static var tokenToWithdraw: String { L10n.tr("Localizable", "Token to withdraw") }
  /// Token you pay
  internal static var tokenYouPay: String { L10n.tr("Localizable", "Token you pay") }
  /// Token you receive
  internal static var tokenYouReceive: String { L10n.tr("Localizable", "Token you receive") }
  /// Token's mint address is not valid
  internal static var tokenSMintAddressIsNotValid: String { L10n.tr("Localizable", "Token's mint address is not valid") }
  /// Tokens
  internal static var tokens: String { L10n.tr("Localizable", "Tokens") }
  /// Top up
  internal static var topUp: String { L10n.tr("Localizable", "Top up") }
  /// Top up balance to continue
  internal static var topUpBalanceToContinue: String { L10n.tr("Localizable", "Top up balance to continue") }
  /// Top up your account
  internal static var topUpYourAccount: String { L10n.tr("Localizable", "Top up your account") }
  /// Top up your account to get started
  internal static var topUpYourAccountToGetStarted: String { L10n.tr("Localizable", "Top up your account to get started") }
  /// Total
  internal static var total: String { L10n.tr("Localizable", "Total") }
  /// Total amount
  internal static var totalAmount: String { L10n.tr("Localizable", "Total amount") }
  /// Total balance
  internal static var totalBalance: String { L10n.tr("Localizable", "Total balance") }
  /// Total fee
  internal static var totalFee: String { L10n.tr("Localizable", "Total fee") }
  /// Total fees
  internal static var totalFees: String { L10n.tr("Localizable", "Total fees") }
  /// Total rewards earned
  internal static var totalRewardsEarned: String { L10n.tr("Localizable", "Total rewards earned") }
  /// Touch ID
  internal static var touchID: String { L10n.tr("Localizable", "Touch ID") }
  /// Transaction
  internal static var transaction: String { L10n.tr("Localizable", "Transaction") }
  /// Transaction detail
  internal static var transactionDetail: String { L10n.tr("Localizable", "Transaction detail") }
  /// Transaction details
  internal static var transactionDetails: String { L10n.tr("Localizable", "Transaction details") }
  /// Transaction failed
  internal static var transactionFailed: String { L10n.tr("Localizable", "Transaction failed") }
  /// Transaction fee
  internal static var transactionFee: String { L10n.tr("Localizable", "Transaction fee") }
  /// Transaction fees
  internal static var transactionFees: String { L10n.tr("Localizable", "Transaction fees") }
  /// Transaction has been confirmed
  internal static var transactionHasBeenConfirmed: String { L10n.tr("Localizable", "Transaction has been confirmed") }
  /// Transaction has been finalized
  internal static var transactionHasBeenFinalized: String { L10n.tr("Localizable", "Transaction has been finalized") }
  /// Transaction has been sent
  internal static var transactionHasBeenSent: String { L10n.tr("Localizable", "Transaction has been sent") }
  /// Transaction ID
  internal static var transactionID: String { L10n.tr("Localizable", "Transaction ID") }
  /// Transaction processing
  internal static var transactionProcessing: String { L10n.tr("Localizable", "Transaction processing") }
  /// Transaction submitted
  internal static var transactionSubmitted: String { L10n.tr("Localizable", "Transaction submitted") }
  /// Transaction succeeded
  internal static var transactionSucceeded: String { L10n.tr("Localizable", "Transaction succeeded") }
  /// Transaction Token
  internal static var transactionToken: String { L10n.tr("Localizable", "Transaction Token") }
  /// Transactions that exceed 20%% slippage tolerance may be %@
  internal static func transactionsThatExceed20SlippageToleranceMayBe(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Transactions that exceed 20% slippage tolerance may be %@", String(describing: p1))
  }
  /// Transfer
  internal static var transfer: String { L10n.tr("Localizable", "Transfer") }
  /// Transfer fee
  internal static var transferFee: String { L10n.tr("Localizable", "Transfer fee") }
  /// Transfer SOL to our payment provider from Key App
  internal static var transferSOLToOurPaymentProviderFromKeyApp: String { L10n.tr("Localizable", "Transfer SOL to our payment provider from Key App") }
  /// Try again
  internal static var tryAgain: String { L10n.tr("Localizable", "Try again") }
  /// Try again later
  internal static var tryAgainLater: String { L10n.tr("Localizable", "Try again later") }
  /// Try another option
  internal static var tryAnotherOption: String { L10n.tr("Localizable", "Try another option") }
  /// Try with account or use an another phone number
  internal static var tryWithAccountOrUseAnAnotherPhoneNumber: String { L10n.tr("Localizable", "Try with account or use an another phone number") }
  /// Try with another account
  internal static var tryWithAnotherAccount: String { L10n.tr("Localizable", "Try with another account") }
  /// Try with another account or use a phone number
  internal static var tryWithAnotherAccountOrUseAPhoneNumber: String { L10n.tr("Localizable", "Try with another account or use a phone number") }
  /// Try with another account or use an another phone number
  internal static var tryWithAnotherAccountOrUseAnAnotherPhoneNumber: String { L10n.tr("Localizable", "Try with another account or use an another phone number") }
  /// Turn off the light
  internal static var turnOffTheLight: String { L10n.tr("Localizable", "Turn off the light") }
  /// Turn on
  internal static var turnOn: String { L10n.tr("Localizable", "Turn on") }
  /// Turn on notifications
  internal static var turnOnNotifications: String { L10n.tr("Localizable", "Turn on notifications") }
  /// Turn on the light
  internal static var turnOnTheLight: String { L10n.tr("Localizable", "Turn on the light") }
  /// Unable to access camera
  internal static var unableToAccessCamera: String { L10n.tr("Localizable", "Unable to access camera") }
  /// Unauthorized
  internal static var unauthorized: String { L10n.tr("Localizable", "Unauthorized") }
  /// Unfortunately, you can not buy in %@, but you can still use other Key App features
  internal static func unfortunatelyYouCanNotBuyInButYouCanStillUseOtherKeyAppFeatures(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Unfortunately, you can not buy in %@, but you can still use other Key App features", String(describing: p1))
  }
  /// Unique one-time link works once only
  internal static var uniqueOneTimeLinkWorksOnceOnly: String { L10n.tr("Localizable", "Unique one-time link works once only") }
  /// United States Dollar
  internal static var unitedStatesDollar: String { L10n.tr("Localizable", "United States Dollar") }
  /// Unknown
  internal static var unknown: String { L10n.tr("Localizable", "Unknown") }
  /// Unknown date
  internal static var unknownDate: String { L10n.tr("Localizable", "Unknown date") }
  /// Unknown error
  internal static var unknownError: String { L10n.tr("Localizable", "Unknown error") }
  /// Unknown time
  internal static var unknownTime: String { L10n.tr("Localizable", "Unknown time") }
  /// Unknown token
  internal static var unknownToken: String { L10n.tr("Localizable", "Unknown token") }
  /// Unstake
  internal static var unstake: String { L10n.tr("Localizable", "Unstake") }
  /// Unstake signature
  internal static var unstakeSignature: String { L10n.tr("Localizable", "Unstake signature") }
  /// unsupported
  internal static var unsupported: String { L10n.tr("Localizable", "unsupported") }
  /// Unsupported recipient's address
  internal static var unsupportedRecipientSAddress: String { L10n.tr("Localizable", "Unsupported recipient's address") }
  /// Update
  internal static var update: String { L10n.tr("Localizable", "Update") }
  /// Updating
  internal static var updating: String { L10n.tr("Localizable", "Updating") }
  /// Updating prices
  internal static var updatingPrices: String { L10n.tr("Localizable", "Updating prices") }
  /// USDC
  internal static var usdc: String { L10n.tr("Localizable", "USDC") }
  /// USDC, USDT, BTC, ETH, SOL and other cryptocurrencies with lightspeed and zero fees
  internal static var usdcusdtbtcethsolAndOtherCryptocurrenciesWithLightspeedAndZeroFees: String { L10n.tr("Localizable", "USDC, USDT, BTC, ETH, SOL and other cryptocurrencies with lightspeed and zero fees") }
  /// Use a seed phrase
  internal static var useASeedPhrase: String { L10n.tr("Localizable", "Use a seed phrase") }
  /// Use all
  internal static var useAll: String { L10n.tr("Localizable", "Use all") }
  /// Use an another phone
  internal static var useAnAnotherPhone: String { L10n.tr("Localizable", "Use an another phone") }
  /// Use another account
  internal static var useAnotherAccount: String { L10n.tr("Localizable", "Use another account") }
  /// Use any latin and special symbols or emojis.
  internal static var useAnyLatinAndSpecialSymbolsOrEmojis: String { L10n.tr("Localizable", "Use any latin and special symbols or emojis.") }
  /// Use any lowercased latin characters and hyphens
  internal static var useAnyLowercasedLatinCharactersAndHyphens: String { L10n.tr("Localizable", "Use any lowercased latin characters and hyphens") }
  /// Use FaceId
  internal static var useFaceId: String { L10n.tr("Localizable", "Use FaceId") }
  /// Use free transactions
  internal static var useFreeTransactions: String { L10n.tr("Localizable", "Use free transactions") }
  /// Use our advanced security to buy,\nsell and hold cryptos
  internal static var useOurAdvancedSecurityToBuySellAndHoldCryptos: String { L10n.tr("Localizable", "Use our advanced security to buy, sell and hold cryptos") }
  /// Use TouchId
  internal static var useTouchId: String { L10n.tr("Localizable", "Use TouchId") }
  /// Use your FaceID for quick access?
  internal static var useYourFaceIDForQuickAccess: String { L10n.tr("Localizable", "Use your FaceID for quick access?") }
  /// Use your social account to continue
  internal static var useYourSocialAccountToContinue: String { L10n.tr("Localizable", "Use your social account to continue") }
  /// Use your TouchID for quick access?
  internal static var useYourTouchIDForQuickAccess: String { L10n.tr("Localizable", "Use your TouchID for quick access?") }
  /// Username
  internal static var username: String { L10n.tr("Localizable", "Username") }
  /// Username %@ was reserved
  internal static func usernameWasReserved(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Username %@ was reserved", String(describing: p1))
  }
  /// Username must contain less than 15 characters
  internal static var usernameMustContainLessThan15Characters: String { L10n.tr("Localizable", "Username must contain less than 15 characters") }
  /// username or address
  internal static var usernameOrAddress: String { L10n.tr("Localizable", "username or address") }
  /// Username was copied to clipboard
  internal static var usernameWasCopiedToClipboard: String { L10n.tr("Localizable", "Username was copied to clipboard") }
  /// using Apple Pay or credit card
  internal static var usingApplePayOrCreditCard: String { L10n.tr("Localizable", "using Apple Pay or credit card") }
  /// Using the maximum %@ amount
  internal static func usingTheMaximumAmount(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Using the maximum %@ amount", String(describing: p1))
  }
  /// Using Wormhole bridge
  internal static var usingWormholeBridge: String { L10n.tr("Localizable", "Using Wormhole bridge") }
  /// Value
  internal static var value: String { L10n.tr("Localizable", "Value") }
  /// Verify manually
  internal static var verifyManually: String { L10n.tr("Localizable", "Verify manually") }
  /// Verify your security key
  internal static var verifyYourSecurityKey: String { L10n.tr("Localizable", "Verify your security key") }
  /// via bank transfer
  internal static var viaBankTransfer: String { L10n.tr("Localizable", "via bank transfer") }
  /// Vietnamese Dong
  internal static var vietnameseDong: String { L10n.tr("Localizable", "Vietnamese Dong") }
  /// View in %@ explorer
  internal static func viewInExplorer(_ p1: Any) -> String {
    return L10n.tr("Localizable", "View in %@ explorer", String(describing: p1))
  }
  /// View in blockchain explorer
  internal static var viewInBlockchainExplorer: String { L10n.tr("Localizable", "View in blockchain explorer") }
  /// View recovery key
  internal static var viewRecoveryKey: String { L10n.tr("Localizable", "View recovery key") }
  /// Visibility in token list
  internal static var visibilityInTokenList: String { L10n.tr("Localizable", "Visibility in token list") }
  /// Visible
  internal static var visible: String { L10n.tr("Localizable", "Visible") }
  /// Vote account
  internal static var voteAccount: String { L10n.tr("Localizable", "Vote account") }
  /// Wait, name checking is going
  internal static var waitNameCheckingIsGoing: String { L10n.tr("Localizable", "Wait, name checking is going") }
  /// Waiting for deposit confirmation
  internal static var waitingForDepositConfirmation: String { L10n.tr("Localizable", "Waiting for deposit confirmation") }
  /// Wallet
  internal static var wallet: String { L10n.tr("Localizable", "Wallet") }
  /// Wallet address
  internal static var walletAddress: String { L10n.tr("Localizable", "Wallet address") }
  /// Wallet address is not valid
  internal static var walletAddressIsNotValid: String { L10n.tr("Localizable", "Wallet address is not valid") }
  /// Wallet name
  internal static var walletName: String { L10n.tr("Localizable", "Wallet name") }
  /// Wallet protection
  internal static var walletProtection: String { L10n.tr("Localizable", "Wallet protection") }
  /// Wallet recovery
  internal static var walletRecovery: String { L10n.tr("Localizable", "Wallet recovery") }
  /// Wallet settings
  internal static var walletSettings: String { L10n.tr("Localizable", "Wallet settings") }
  /// wallet
  internal static var walletRename: String { L10n.tr("Localizable", "wallet_rename") }
  /// Wallets
  internal static var wallets: String { L10n.tr("Localizable", "Wallets") }
  /// Warning
  internal static var warning: String { L10n.tr("Localizable", "Warning") }
  /// WARNING: The seed phrase will not be shown again, copy it down or save in your password manager to recover this wallet in the future.
  internal static var warningTheSeedPhraseWillNotBeShownAgainCopyItDownOrSaveInYourPasswordManagerToRecoverThisWalletInTheFuture: String { L10n.tr("Localizable", "WARNING: The seed phrase will not be shown again, copy it down or save in your password manager to recover this wallet in the future.") }
  /// We bridge it to Solana with Wormhole
  internal static var weBridgeItToSolanaWithWormhole: String { L10n.tr("Localizable", "We bridge it to Solana with Wormhole") }
  /// We cannot retrieve the transaction status without the internet
  internal static var weCannotRetrieveTheTransactionStatusWithoutTheInternet: String { L10n.tr("Localizable", "We cannot retrieve the transaction status without the internet") }
  /// We can’t SMS you
  internal static var weCanTSMSYou: String { L10n.tr("Localizable", "We can’t SMS you") }
  /// we do not recommend sending it to this address.
  internal static var weDoNotRecommendSendingItToThisAddress: String { L10n.tr("Localizable", "we do not recommend sending it to this address.") }
  /// We have not supported this type of biometry authentication yet
  internal static var weHaveNotSupportedThisTypeOfBiometryAuthenticationYet: String { L10n.tr("Localizable", "We have not supported this type of biometry authentication yet") }
  /// We left a minimum SOL balance to save the account address
  internal static var weLeftAMinimumSOLBalanceToSaveTheAccountAddress: String { L10n.tr("Localizable", "We left a minimum SOL balance to save the account address") }
  /// We provide you with the possibility to use secure and trusted protocols.
  internal static var weProvideYouWithThePossibilityToUseSecureAndTrustedProtocols: String { L10n.tr("Localizable", "We provide you with the possibility to use secure and trusted protocols.") }
  /// We refund bridging costs for any transactions over $50
  internal static var weRefundBridgingCostsForAnyTransactionsOver50: String { L10n.tr("Localizable", "We refund bridging costs for any transactions over $50") }
  /// We refund bridging costs for any transactions over %@
  internal static func weRefundBridgingCostsForAnyTransactionsOver(_ p1: Any) -> String {
    return L10n.tr("Localizable", "We refund bridging costs for any transactions over %@", String(describing: p1))
  }
  /// We suggest you also to enable push notifications
  internal static var weSuggestYouAlsoToEnablePushNotifications: String { L10n.tr("Localizable", "We suggest you also to enable push notifications") }
  /// We suggest you try again later because we will not be able to verify the address if you continue.
  internal static var weSuggestYouTryAgainLaterBecauseWeWillNotBeAbleToVerifyTheAddressIfYouContinue: String { L10n.tr("Localizable", "We suggest you try again later because we will not be able to verify the address if you continue.") }
  /// We use FaceID to secure your transactions
  internal static var weUseFaceIDToSecureYourTransactions: String { L10n.tr("Localizable", "We use FaceID to secure your transactions") }
  /// we've created some security keywords for you.
  internal static var weVeCreatedSomeSecurityKeywordsForYou: String { L10n.tr("Localizable", "we've created some security keywords for you.") }
  /// We've noticed that you're using a new device.
  internal static var weVeNoticedThatYouReUsingANewDevice: String { L10n.tr("Localizable", "We've noticed that you're using a new device.") }
  /// week
  internal static var week: String { L10n.tr("Localizable", "week") }
  /// Welcome back!
  internal static var welcomeBack: String { L10n.tr("Localizable", "Welcome back!") }
  /// Welcome back, %@
  internal static func welcomeBack(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Welcome back, %@", String(describing: p1))
  }
  /// Welcome\nto Key App
  internal static var welcomeToKeyApp: String { L10n.tr("Localizable", "Welcome to Key App") }
  /// Well done!
  internal static var wellDone: String { L10n.tr("Localizable", "Well done!") }
  /// Well, well
  internal static var wellWell: String { L10n.tr("Localizable", "Well, well") }
  /// We’ve locked your wallet, try again in %@
  internal static func weVeLockedYourWalletTryAgainIn(_ p1: Any) -> String {
    return L10n.tr("Localizable", "We’ve locked your wallet, try again in %@", String(describing: p1))
  }
  /// What is a security key?
  internal static var whatIsASecurityKey: String { L10n.tr("Localizable", "What is a security key?") }
  /// What is Solend?
  internal static var whatIsSolend: String { L10n.tr("Localizable", "What is Solend?") }
  /// What tokens can I receive?
  internal static var whatTokensCanIReceive: String { L10n.tr("Localizable", "What tokens can I receive?") }
  /// What’s your number? 🤙
  internal static var whatSYourNumber🤙: String { L10n.tr("Localizable", "What’s your number? 🤙") }
  /// When you delete your account, you will lose access to your funds.
  internal static var whenYouDeleteYourAccountYouWillLoseAccessToYourFunds: String { L10n.tr("Localizable", "When you delete your account, you will lose access to your funds.") }
  /// When you trade the token for the first time, Solana charges a one-time fee for creating an account.
  internal static var whenYouTradeTheTokenForTheFirstTimeSolanaChargesAOneTimeFeeForCreatingAnAccount: String { L10n.tr("Localizable", "When you trade the token for the first time, Solana charges a one-time fee for creating an account.") }
  /// Where can I find one?
  internal static var whereCanIFindOne: String { L10n.tr("Localizable", "Where can I find one?") }
  /// Which cryptocurrencies can I use?
  internal static var whichCryptocurrenciesCanIUse: String { L10n.tr("Localizable", "Which cryptocurrencies can I use?") }
  /// Will be as a primary secure check
  internal static var willBeAsAPrimarySecureCheck: String { L10n.tr("Localizable", "Will be as a primary secure check") }
  /// Will be paid by Key App\nWe take care of all transfers costs.
  internal static var willBePaidByKeyAppWeTakeCareOfAllTransfersCosts: String { L10n.tr("Localizable", "Will be paid by Key App\nWe take care of all transfers costs.") }
  /// Will be sent to
  internal static var willBeSentTo: String { L10n.tr("Localizable", "Will be sent to") }
  /// will cost
  internal static var willCost: String { L10n.tr("Localizable", "will cost") }
  /// With Key App, all transactions you make on the Solana network are free
  internal static var withKeyAppAllTransactionsYouMakeOnTheSolanaNetworkAreFree: String { L10n.tr("Localizable", "With Key App, all transactions you make on the Solana network are free") }
  /// Withdraw
  internal static var withdraw: String { L10n.tr("Localizable", "Withdraw") }
  /// Withdraw all
  internal static var withdrawAll: String { L10n.tr("Localizable", "Withdraw all") }
  /// Withdraw funds
  internal static var withdrawFunds: String { L10n.tr("Localizable", "Withdraw funds") }
  /// Withdraw rewards or funds at any time
  internal static var withdrawRewardsOrFundsAtAnyTime: String { L10n.tr("Localizable", "Withdraw rewards or funds at any time") }
  /// Withdraw your funds with all rewards at any time
  internal static var withdrawYourFundsWithAllRewardsAtAnyTime: String { L10n.tr("Localizable", "Withdraw your funds with all rewards at any time") }
  /// Withdrawal fee
  internal static var withdrawalFee: String { L10n.tr("Localizable", "Withdrawal fee") }
  /// Without account details
  internal static var withoutAccountDetails: String { L10n.tr("Localizable", "Without account details") }
  /// Would be completed on the Ethereum network
  internal static var wouldBeCompletedOnTheEthereumNetwork: String { L10n.tr("Localizable", "Would be completed on the Ethereum network") }
  /// Wowlet for people, not for tokens
  internal static var wowletForPeopleNotForTokens: String { L10n.tr("Localizable", "Wowlet for people, not for tokens") }
  /// Wrapped %@ by %@
  internal static func wrappedBy(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Wrapped %@ by %@", String(describing: p1), String(describing: p2))
  }
  /// Wrong hash format
  internal static var wrongHashFormat: String { L10n.tr("Localizable", "Wrong hash format") }
  /// Wrong keypair format
  internal static var wrongKeypairFormat: String { L10n.tr("Localizable", "Wrong keypair format") }
  /// Wrong order or seed phrase, please check it and try again
  internal static var wrongOrderOrSeedPhrasePleaseCheckItAndTryAgain: String { L10n.tr("Localizable", "Wrong order or seed phrase, please check it and try again") }
  /// Plural format key: "%#@variable_0@"
  internal static func wrongPinCodeDAttemptSLeft(_ p1: Int) -> String {
    return L10n.tr("Localizable", "Wrong Pin-code, %d attempt(s) left", p1)
  }
  /// Wrong pubkey format
  internal static var wrongPubkeyFormat: String { L10n.tr("Localizable", "Wrong pubkey format") }
  /// Wrong signature
  internal static var wrongSignature: String { L10n.tr("Localizable", "Wrong signature") }
  /// Wrong signature format
  internal static var wrongSignatureFormat: String { L10n.tr("Localizable", "Wrong signature format") }
  /// Wrong wallet address
  internal static var wrongWalletAddress: String { L10n.tr("Localizable", "Wrong wallet address") }
  /// year
  internal static var year: String { L10n.tr("Localizable", "year") }
  /// Yes, delete it
  internal static var yesDeleteIt: String { L10n.tr("Localizable", "Yes, delete it") }
  /// Yes, delete my account
  internal static var yesDeleteMyAccount: String { L10n.tr("Localizable", "Yes, delete my account") }
  /// Yesterday
  internal static var yesterday: String { L10n.tr("Localizable", "Yesterday") }
  /// Yielding
  internal static var yielding: String { L10n.tr("Localizable", "Yielding") }
  /// You **%@** to pay for account creation, but if someone sends renBTC to your address, it will be created for you.
  internal static func youToPayForAccountCreationButIfSomeoneSendsRenBTCToYourAddressItWillBeCreatedForYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "You **%@** to pay for account creation, but if someone sends renBTC to your address, it will be created for you.", String(describing: p1))
  }
  /// You can choose in which currency to pay with below.
  internal static var youCanChooseInWhichCurrencyToPayWithBelow: String { L10n.tr("Localizable", "You can choose in which currency to pay with below.") }
  /// You can choose which currency to pay in below.
  internal static var youCanChooseWhichCurrencyToPayInBelow: String { L10n.tr("Localizable", "You can choose which currency to pay in below.") }
  /// You can compare a cryptocurrency wallet to a password manager for crypto, and a security key to a master password.\n\nA security key is a series of 12 or 24 words generated by the wallet that give you access to its associated crypto.
  internal static var youCanCompareACryptocurrencyWallet: String { L10n.tr("Localizable", "You can compare a cryptocurrency wallet") }
  /// You can enter “You pay” field only
  internal static var youCanEnterYouPayFieldOnly: String { L10n.tr("Localizable", "You can enter “You pay” field only") }
  /// You can not send tokens to yourself
  internal static var youCanNotSendTokensToYourself: String { L10n.tr("Localizable", "You can not send tokens to yourself") }
  /// You can only cash out SOL
  internal static var youCanOnlyCashOutSOL: String { L10n.tr("Localizable", "You can only cash out SOL") }
  /// You can receive %@ by providing this address, QR code or username:
  internal static func youCanReceiveByProvidingThisAddressQRCodeOrUsername(_ p1: Any) -> String {
    return L10n.tr("Localizable", "You can receive %@ by providing this address, QR code or username:", String(describing: p1))
  }
  /// You can withdraw rewards or funds at any time
  internal static var youCanWithdrawRewardsOrFundsAtAnyTime: String { L10n.tr("Localizable", "You can withdraw rewards or funds at any time") }
  /// You can't receive funds with it
  internal static var youCanTReceiveFundsWithIt: String { L10n.tr("Localizable", "You can't receive funds with it") }
  /// You cannot send funds to this address because it belongs to another token
  internal static var youCannotSendFundsToThisAddressBecauseItBelongsToAnotherToken: String { L10n.tr("Localizable", "You cannot send funds to this address because it belongs to another token") }
  /// You cannot send tokens to yourself
  internal static var youCannotSendTokensToYourself: String { L10n.tr("Localizable", "You cannot send tokens to yourself") }
  /// You can’t receive money with it
  internal static var youCanTReceiveMoneyWithIt: String { L10n.tr("Localizable", "You can’t receive money with it") }
  /// You can’t send less than %@
  internal static func youCanTSendLessThan(_ p1: Any) -> String {
    return L10n.tr("Localizable", "You can’t send less than %@", String(describing: p1))
  }
  /// You can’t swap between the same token
  internal static var youCanTSwapBetweenTheSameToken: String { L10n.tr("Localizable", "You can’t swap between the same token") }
  /// You first need to buy %@ and then swap for %@ on the Main Page
  internal static func youFirstNeedToBuyAndThenSwapForOnTheMainPage(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "You first need to buy %@ and then swap for %@ on the Main Page", String(describing: p1), String(describing: p2))
  }
  /// You get
  internal static var youGet: String { L10n.tr("Localizable", "You get") }
  /// You have no internet connection
  internal static var youHaveNoInternetConnection: String { L10n.tr("Localizable", "You have no internet connection") }
  /// You have not made any transaction yet
  internal static var youHaveNotMadeAnyTransactionYet: String { L10n.tr("Localizable", "You have not made any transaction yet") }
  /// You have successfully set your PIN
  internal static var youHaveSuccessfullySetYourPIN: String { L10n.tr("Localizable", "You have successfully set your PIN") }
  /// You have unsaved changes that will be lost if you decide to leave
  internal static var youHaveUnsavedChangesThatWillBeLostIfYouDecideToLeave: String { L10n.tr("Localizable", "You have unsaved changes that will be lost if you decide to leave") }
  /// You must select a wallet to send
  internal static var youMustSelectAWalletToSend: String { L10n.tr("Localizable", "You must select a wallet to send") }
  /// You need to buy USDC and Swap on Main Page
  internal static var youNeedToBuyUSDCAndSwapOnMainPage: String { L10n.tr("Localizable", "You need to buy USDC and Swap on Main Page") }
  /// you need to make a transaction
  internal static var youNeedToMakeATransaction: String { L10n.tr("Localizable", "you need to make a transaction") }
  /// You need to send
  internal static var youNeedToSend: String { L10n.tr("Localizable", "You need to send") }
  /// You need to send %@ SOL
  internal static func youNeedToSendSOL(_ p1: Any) -> String {
    return L10n.tr("Localizable", "You need to send %@ SOL", String(describing: p1))
  }
  /// You need to send SOL to the address in the description to finish your cash out operation.
  internal static var youNeedToSendSOLToTheAddressInTheDescriptionToFinishYourCashOutOperation: String { L10n.tr("Localizable", "You need to send SOL to the address in the description to finish your cash out operation.") }
  /// You only need to sign a transaction with Key App
  internal static var youOnlyNeedToSignATransactionWithKeyApp: String { L10n.tr("Localizable", "You only need to sign a transaction with Key App") }
  /// You pay
  internal static var youPay: String { L10n.tr("Localizable", "You pay") }
  /// You receive
  internal static var youReceive: String { L10n.tr("Localizable", "You receive") }
  /// You were signed out
  internal static var youWereSignedOut: String { L10n.tr("Localizable", "You were signed out") }
  /// You will be redirected to our payment provider
  internal static var youWillBeRedirectedToOurPaymentProvider: String { L10n.tr("Localizable", "You will be redirected to our payment provider") }
  /// You will get
  internal static var youWillGet: String { L10n.tr("Localizable", "You will get") }
  /// You will have to pay a one-time fee (~%@) to create an account for this address
  internal static func youWillHaveToPayAOneTimeFeeToCreateAnAccountForThisAddress(_ p1: Any) -> String {
    return L10n.tr("Localizable", "You will have to pay a one-time fee (~%@) to create an account for this address", String(describing: p1))
  }
  /// You will need to enter your IBAN and pass KYC
  internal static var youWillNeedToEnterYourIBANAndPassKYC: String { L10n.tr("Localizable", "You will need to enter your IBAN and pass KYC") }
  /// You will need your social account or phone number to log in
  internal static var youWillNeedYourSocialAccountOrPhoneNumberToLogIn: String { L10n.tr("Localizable", "You will need your social account or phone number to log in") }
  /// You will not be able to use free transactions within the Solana network with Key App.
  internal static var youWillNotBeAbleToUseFreeTransactionsWithinTheSolanaNetworkWithKeyApp: String { L10n.tr("Localizable", "You will not be able to use free transactions within the Solana network with Key App.") }
  /// You will not be able to use the old device for recovery
  internal static var youWillNotBeAbleToUseTheOldDeviceForRecovery: String { L10n.tr("Localizable", "You will not be able to use the old device for recovery") }
  /// You will send
  internal static var youWillSend: String { L10n.tr("Localizable", "You will send") }
  /// You will withdraw
  internal static var youWillWithdraw: String { L10n.tr("Localizable", "You will withdraw") }
  /// Your %@ address
  internal static func yourAddress(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Your %@ address", String(describing: p1))
  }
  /// Your account does not have enough %@ to cover fees
  internal static func yourAccountDoesNotHaveEnoughToCoverFees(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Your account does not have enough %@ to cover fees", String(describing: p1))
  }
  /// Your account does not have enough SOL to cover fee
  internal static var yourAccountDoesNotHaveEnoughSOLToCoverFee: String { L10n.tr("Localizable", "Your account does not have enough SOL to cover fee") }
  /// Your bank account via Moonpay
  internal static var yourBankAccountViaMoonpay: String { L10n.tr("Localizable", "Your bank account via Moonpay") }
  /// Your connection to the Internet has been interrupted.
  internal static var yourConnectionToTheInternetHasBeenInterrupted: String { L10n.tr("Localizable", "Your connection to the Internet has been interrupted.") }
  /// Your crypto is under control
  internal static var yourCryptoIsUnderControl: String { L10n.tr("Localizable", "Your crypto is under control") }
  /// Your current PIN code
  internal static var yourCurrentPINCode: String { L10n.tr("Localizable", "Your current PIN code") }
  /// Your deposits
  internal static var yourDeposits: String { L10n.tr("Localizable", "Your deposits") }
  /// Your device does not support biometrics authentication
  internal static var yourDeviceDoesNotSupportBiometricsAuthentication: String { L10n.tr("Localizable", "Your device does not support biometrics authentication") }
  /// Your Ethereum address was copied
  internal static var yourEthereumAddressWasCopied: String { L10n.tr("Localizable", "Your Ethereum address was copied") }
  /// Your PIN
  internal static var yourPIN: String { L10n.tr("Localizable", "Your PIN") }
  /// Your PIN was changed
  internal static var yourPINWasChanged: String { L10n.tr("Localizable", "Your PIN was changed") }
  /// Your public %@ address
  internal static func yourPublicAddress(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Your public %@ address", String(describing: p1))
  }
  /// Your recovery kit
  internal static var yourRecoveryKit: String { L10n.tr("Localizable", "Your recovery kit") }
  /// Your removal request has been accepted
  internal static var yourRemovalRequestHasBeenAccepted: String { L10n.tr("Localizable", "Your removal request has been accepted") }
  /// Your security key
  internal static var yourSecurityKey: String { L10n.tr("Localizable", "Your security key") }
  /// Your seed phrase
  internal static var yourSeedPhrase: String { L10n.tr("Localizable", "Your seed phrase") }
  /// Your seed phrase must never be shared
  internal static var yourSeedPhraseMustNeverBeShared: String { L10n.tr("Localizable", "Your seed phrase must never be shared") }
  /// Your Solana address was copied
  internal static var yourSolanaAddressWasCopied: String { L10n.tr("Localizable", "Your Solana address was copied") }
  /// Your tokens
  internal static var yourTokens: String { L10n.tr("Localizable", "Your tokens") }
  /// Your transaction may be frontrun
  internal static var yourTransactionMayBeFrontrun: String { L10n.tr("Localizable", "Your transaction may be frontrun") }
  /// Your username
  internal static var yourUsername: String { L10n.tr("Localizable", "Your username") }
  /// Your username allows you to receive any token within the Solana network even if it is not included in your wallet token list.
  internal static var yourUsernameAllowsYouToReceiveAnyTokenWithinTheSolanaNetworkEvenIfItIsNotIncludedInYourWalletTokenList: String { L10n.tr("Localizable", "Your username allows you to receive any token within the Solana network even if it is not included in your wallet token list.") }
  /// Your username was copied
  internal static var yourUsernameWasCopied: String { L10n.tr("Localizable", "Your username was copied") }
  /// Your wallet has been created! Just a few moments to start a crypto adventure
  internal static var yourWalletHasBeenCreatedJustAFewMomentsToStartACryptoAdventure: String { L10n.tr("Localizable", "Your wallet has been created! Just a few moments to start a crypto adventure") }
  /// Your wallet is at risk if you do not back it up
  internal static var yourWalletIsAtRiskIfYouDoNotBackItUp: String { L10n.tr("Localizable", "Your wallet is at risk if you do not back it up") }
  /// Your wallet is backed up
  internal static var yourWalletIsBackedUp: String { L10n.tr("Localizable", "Your wallet is backed up") }
  /// Your wallet list does not contain a renBTC account, and to create one **%@**.
  internal static func yourWalletListDoesNotContainARenBTCAccountAndToCreateOne(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Your wallet list does not contain a renBTC account, and to create one **%@**", String(describing: p1))
  }
  /// Your wallet needs backup
  internal static var yourWalletNeedsBackup: String { L10n.tr("Localizable", "Your wallet needs backup") }
  /// Your wallets
  internal static var yourWallets: String { L10n.tr("Localizable", "Your wallets") }
  /// You’re going to buy %@
  internal static func youReGoingToBuy(_ p1: Any) -> String {
    return L10n.tr("Localizable", "You’re going to buy %@", String(describing: p1))
  }
  /// You’ve got
  internal static var youVeGot: String { L10n.tr("Localizable", "You’ve got") }
  /// You’ve not sent
  internal static var youVeNotSent: String { L10n.tr("Localizable", "You’ve not sent") }
  /// ✅ Seed phrase copied to clipboard!
  internal static var seedPhraseCopiedToClipboard: String { L10n.tr("Localizable", "✅ Seed phrase copied to clipboard!") }
  /// ✅ Using the MAX amount
  internal static var usingTheMAXAmount: String { L10n.tr("Localizable", "✅ Using the MAX amount") }
  /// ✌️ Great! Your new PIN is set.
  internal static var _️GreatYourNewPINIsSet: String { L10n.tr("Localizable", "✌️ Great! Your new PIN is set.") }
  /// 🕑 Sending your deposit...
  internal static var 🕑SendingYourDeposit: String { L10n.tr("Localizable", "🕑 Sending your deposit...") }
  /// 😓 name is not available
  internal static var 😓NameIsNotAvailable: String { L10n.tr("Localizable", "😓 name is not available") }

  internal enum DoesnTWork {
    /// %@ doesn't work. Try another option
    internal static func tryAnotherOption(_ p1: Any) -> String {
      return L10n.tr("Localizable", "%@ doesn't work. Try another option", String(describing: p1))
    }
  }

  internal enum SentYouViaKeyApp {
    /// %@ sent you %@ via Key App. Follow the link to claim your funds: %@
    internal static func followTheLinkToClaimYourFunds(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
      return L10n.tr("Localizable", "%@ sent you %@ via Key App. Follow the link to claim your funds: %@", String(describing: p1), String(describing: p2), String(describing: p3))
    }
  }

  internal enum ASeedPhraseIsLikeAPassword {
    /// A seed phrase is like a password. It allows you to access and manage your crypto.
    internal static var itAllowsYouToAccessAndManageYourCrypto: String { L10n.tr("Localizable", "A seed phrase is like a password. It allows you to access and manage your crypto.") }
  }

  internal enum AddATokenToYourWallet {
    /// Add a token to your wallet.\nThis will cost
    internal static var thisWillCost: String { L10n.tr("Localizable", "Add a token to your wallet.\nThis will cost") }
  }

  internal enum AddressNotFound {
    /// Address not found. Try another one
    internal static var tryAnotherOne: String { L10n.tr("Localizable", "Address not found. Try another one") }
  }

  internal enum After2MoreIncorrectAttemptsWeLlLogYouOutOfTheCurrentAccountForYourSafety {
    /// After 2 more incorrect attempts, we'll log you out of the current account for your safety.\n\nYou can logout right now to create a new PIN for the app.
    internal static var youCanLogoutRightNowToCreateANewPINForTheApp: String { L10n.tr("Localizable", "After 2 more incorrect attempts, we'll log you out of the current account for your safety.\n\nYou can logout right now to create a new PIN for the app.") }
  }

  internal enum AllTransactionsOverAreFree {
    /// All transactions over %@ are free. Key App will cover all fees for you.
    internal static func keyAppWillCoverAllFeesForYou(_ p1: Any) -> String {
      return L10n.tr("Localizable", "All transactions over %@ are free. Key App will cover all fees for you.", String(describing: p1))
    }
  }

  internal enum AllYourFundsAreInsured {
    /// All your funds are insured. Withdraw your\ndeposit with all rewards at any time.
    internal static var withdrawYourDepositWithAllRewardsAtAnyTime: String { L10n.tr("Localizable", "All your funds are insured. Withdraw your\ndeposit with all rewards at any time.") }
  }

  internal enum AnErrorOccuredWhileProcessingAnInstruction {
    /// An error occured while processing an instruction. The first element of the tuple indicates the instruction index in which the error occured.
    internal static var theFirstElementOfTheTupleIndicatesTheInstructionIndexInWhichTheErrorOccured: String { L10n.tr("Localizable", "An error occured while processing an instruction. The first element of the tuple indicates the instruction index in which the error occured.") }
  }

  internal enum ApartFromYouNoOneKeepsYourEntireSeedPhrase {
    /// Apart from you, no one keeps your entire seed phrase. The parts are distributed decentralized on Torus Network nodes
    internal static var thePartsAreDistributedDecentralizedOnTorusNetworkNodes: String { L10n.tr("Localizable", "Apart from you, no one keeps your entire seed phrase. The parts are distributed decentralized on Torus Network nodes") }
  }

  internal enum BeSureAllDetailsAreCorrectBeforeConfirmingTheTransaction {
    /// Be sure all details are correct before confirming the transaction. Once confirmed, it cannot be reversed.
    internal static var onceConfirmedItCannotBeReversed: String { L10n.tr("Localizable", "Be sure all details are correct before confirming the transaction. Once confirmed, it cannot be reversed.") }
  }

  internal enum CannotCalculateFees {
    /// Cannot calculate fees. Try again
    internal static var tryAgain: String { L10n.tr("Localizable", "Cannot calculate fees. Try again") }
  }

  internal enum CheckEnteredAccountInfoForSending {
    /// Check entered account info for sending.\nIt should be account in Solana network
    internal static var itShouldBeAccountInSolanaNetwork: String { L10n.tr("Localizable", "Check entered account info for sending. It should be account in Solana network") }
  }

  internal enum CouldNotCheckNameSAvailability {
    /// Could not check name’s availability. Please check your internet connection!
    internal static var pleaseCheckYourInternetConnection: String { L10n.tr("Localizable", "Could not check name’s availability. Please check your internet connection!") }
  }

  internal enum CouldNotRetrieveBalancesForThisTokensPair {
    /// Could not retrieve balances for this tokens pair. Please try selecting again!
    internal static var pleaseTrySelectingAgain: String { L10n.tr("Localizable", "Could not retrieve balances for this tokens pair. Please try selecting again!") }
  }

  internal enum DepositYourCrypto {
    /// Deposit your crypto. Earn up to %@ on %@.
    internal static func earnUpToOn(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "Deposit your crypto. Earn up to %@ on %@.", String(describing: p1), String(describing: p2))
    }
    /// Deposit your crypto. Earn up to 6%% on USD
    internal static var earnUpTo6OnUSD: String { L10n.tr("Localizable", "Deposit your crypto. Earn up to 6%% on USD ") }
  }

  internal enum DonTWorryYourDepositsAreSafe {
    /// Don't worry, your deposits are safe. Somehow, withdrawal did not happen
    internal static var somehowWithdrawalDidNotHappen: String { L10n.tr("Localizable", "Don't worry, your deposits are safe. Somehow, withdrawal did not happen") }
    /// Don't worry, your deposits are safe. We just\nhave issues with showing the info.
    internal static var weJustHaveIssuesWithShowingTheInfo: String { L10n.tr("Localizable", "Don't worry, your deposits are safe. We just\nhave issues with showing the info.") }
  }

  internal enum EachTokenInThisListIsAvailableForReceivingWithThisAddressYouCanSearchForATokenByTypingItsNameOrTicker {
    /// Each token in this list is available for receiving with this address; you can search for a token by typing its name or ticker.\n\nIf a token is not on this list, we do not recommend sending it to this address.
    internal static var ifATokenIsNotOnThisListWeDoNotRecommendSendingItToThisAddress: String { L10n.tr("Localizable", "Each token in this list is available for receiving with this address; you can search for a token by typing its name or ticker.\n\nIf a token is not on this list, we do not recommend sending it to this address.") }
  }

  internal enum EachTransactionToThisDepositAddressTakesAbout60MinutesToComplete {
    /// Each transaction to this deposit address takes about 60 minutes to complete. For security reasons, you will need to wait for 6 block confirmations before you can mint renBTC on Solana.
    internal static var forSecurityReasonsYouWillNeedToWaitFor6BlockConfirmationsBeforeYouCanMintRenBTCOnSolana: String { L10n.tr("Localizable", "Each transaction to this deposit address takes about 60 minutes to complete. For security reasons, you will need to wait for 6 block confirmations before you can mint renBTC on Solana.") }
  }

  internal enum ErrorCheckingAddressValidity {
    /// Error checking address' validity. Are you sure it's correct?
    internal static var areYouSureItSCorrect: String { L10n.tr("Localizable", "Error checking address' validity. Are you sure it's correct?") }
  }

  internal enum ErrorFindingSwappingRoutes {
    /// Error finding swapping routes. Tap here to try again!
    internal static var tapHereToTryAgain: String { L10n.tr("Localizable", "Error finding swapping routes. Tap here to try again!") }
  }

  internal enum ErrorWhenRetrievingCreationFee {
    /// Error when retrieving creation fee.\nTap to try again
    internal static var tapToTryAgain: String { L10n.tr("Localizable", "Error when retrieving creation fee.\nTap to try again") }
  }

  internal enum ErrorWithDeleting {
    /// Error with deleting. Try again
    internal static var tryAgain: String { L10n.tr("Localizable", "Error with deleting. Try again") }
  }

  internal enum IfYouSwitchDevicesYouCanEasilyRestoreYourWallet {
    /// If you switch devices, you can easily restore your wallet. No private keys needed.
    internal static var noPrivateKeysNeeded: String { L10n.tr("Localizable", "If you switch devices, you can easily restore your wallet. No private keys needed.") }
  }

  internal enum IncorrectPIN {
    /// Incorrect PIN. Try again
    internal static var tryAgain: String { L10n.tr("Localizable", "Incorrect PIN. Try again") }
  }

  internal enum InvalidValueOfOTP {
    /// Invalid value of OTP. Please try again to input correct value of OTP
    internal static var pleaseTryAgainToInputCorrectValueOfOTP: String { L10n.tr("Localizable", "Invalid value of OTP. Please try again to input correct value of OTP") }
  }

  internal enum ItUsuallyTakesUpTo3BusinessDays {
    /// It usually takes up to 3 business days. Any questions regarding your transaction can be answered via
    internal static var anyQuestionsRegardingYourTransactionCanBeAnsweredVia: String { L10n.tr("Localizable", "It usually takes up to 3 business days. Any questions regarding your transaction can be answered via") }
  }

  internal enum KeepYourPinSafe {
    /// Keep your pin safe. Hide your pin from other people.
    internal static var hideYourPinFromOtherPeople: String { L10n.tr("Localizable", "Keep your pin safe. Hide your pin from other people.") }
  }

  internal enum KeyAppCannotScanQRCodesWithoutAccessToYourCamera {
    /// Key App cannot scan QR codes without access to your camera. Please enable access under Privacy settings.
    internal static var pleaseEnableAccessUnderPrivacySettings: String { L10n.tr("Localizable", "Key App cannot scan QR codes without access to your camera. Please enable access under Privacy settings.") }
  }

  internal enum KeyAppRespectsYourPrivacyItCanTAccessYourFundsOrPersonalDetails {
    /// Key App respects your privacy - it can't access your funds or personal details. Your information stays securely stored on your device and in the blockchain.
    internal static var yourInformationStaysSecurelyStoredOnYourDeviceAndInTheBlockchain: String { L10n.tr("Localizable", "Key App respects your privacy - it can't access your funds or personal details. Your information stays securely stored on your device and in the blockchain") }
  }

  internal enum KeyAppWillAutomaticallyMatchYourWithdrawalTargetAddressToTheCorrectNetworkForMostWithdrawals {
    /// Key App will automatically match your withdrawal target address to the correct network for most withdrawals. However, before sending your funds, make sure to double-check the selected network.
    internal static var howeverBeforeSendingYourFundsMakeSureToDoubleCheckTheSelectedNetwork: String { L10n.tr("Localizable", "Key App will automatically match your withdrawal target address to the correct network for most withdrawals. However, before sending your funds, make sure to double-check the selected network.") }
  }

  internal enum LikeADepositButWithCrypto {
    /// Like a deposit but with crypto.\nLow risks, all your funds are insured.
    internal static var lowRisksAllYourFundsAreInsured: String { L10n.tr("Localizable", "Like a deposit but with crypto.\nLow risks, all your funds are insured.") }
  }

  internal enum LimitIsOneTimeLinksPerDay {
    /// Limit is %@ one-time links per day. Try tomorrow
    internal static func tryTomorrow(_ p1: Any) -> String {
      return L10n.tr("Localizable", "Limit is %@ one-time links per day. Try tomorrow", String(describing: p1))
    }
  }

  internal enum LowSlippage {
    /// Low slippage %@. We recommend to increase slippage manually
    internal static func weRecommendToIncreaseSlippageManually(_ p1: Any) -> String {
      return L10n.tr("Localizable", "Low slippage %@. We recommend to increase slippage manually", String(describing: p1))
    }
  }

  internal enum NobodyCanAccessYourPrivateKeys {
    /// Nobody can access your private keys.\nYour data is fully safe
    internal static var yourDataIsFullySafe: String { L10n.tr("Localizable", "Nobody can access your private keys. Your data is fully safe") }
  }

  internal enum OnTheSolanaNetworkTheFirstTransactionsInADayArePaidByKeyApp {
    /// On the Solana network, the first %@ transactions in a day are paid by Key App. Subsequent transactions will be charged based on the Solana blockchain gas fee.
    internal static func subsequentTransactionsWillBeChargedBasedOnTheSolanaBlockchainGasFee(_ p1: Any) -> String {
      return L10n.tr("Localizable", "On the Solana network, the first %@ transactions in a day are paid by Key App. Subsequent transactions will be charged based on the Solana blockchain gas fee.", String(describing: p1))
    }
  }

  internal enum OnlyYouHaveAccessToYourFunds {
    /// Only you have access to your funds. You can recover your wallet using your phone or email
    internal static var youCanRecoverYourWalletUsingYourPhoneOrEmail: String { L10n.tr("Localizable", "Only you have access to your funds. You can recover your wallet using your phone or email") }
  }

  internal enum OopsSomethingWentWrong {
    /// Oops, something went wrong.\nPlease try again later
    internal static var pleaseTryAgainLater: String { L10n.tr("Localizable", "Oops, something went wrong.\nPlease try again later") }
  }

  internal enum PINDoesnTMatch {
    /// PIN doesn’t match. Try again
    internal static var tryAgain: String { L10n.tr("Localizable", "PIN doesn’t match. Try again") }
  }

  internal enum PasscodeNotSet {
    /// Passcode not set. So we can’t verify you as the device’s owner.
    internal static var soWeCanTVerifyYouAsTheDeviceSOwner: String { L10n.tr("Localizable", "Passcode not set. So we can’t verify you as the device’s owner.") }
  }

  internal enum PayingTokenIsNotValid {
    /// Paying token is not valid. Please choose another one
    internal static var pleaseChooseAnotherOne: String { L10n.tr("Localizable", "Paying token is not valid. Please choose another one") }
  }

  internal enum ReceivedNewTokens {
    /// Received new tokens. Downloading receipt...
    internal static var downloadingReceipt: String { L10n.tr("Localizable", "Received new tokens. Downloading receipt...") }
  }

  internal enum SMSWillNotBeDelivered {
    /// SMS will not be delivered. Please change phone number
    internal static var pleaseChangePhoneNumber: String { L10n.tr("Localizable", "SMS will not be delivered. Please change phone number") }
    /// SMS will not be delivered. Please check your phone settings
    internal static var pleaseCheckYourPhoneSettings: String { L10n.tr("Localizable", "SMS will not be delivered. Please check your phone settings") }
    /// SMS will not be delivered. Please try with social login
    internal static var pleaseTryWithSocialLogin: String { L10n.tr("Localizable", "SMS will not be delivered. Please try with social login") }
  }

  internal enum SOLWasSentToMoonpayAndIsBeingProcessed {
    /// SOL was sent to Moonpay and is being processed. Any questions regarding your transaction can be answered via
    internal static var anyQuestionsRegardingYourTransactionCanBeAnsweredVia: String { L10n.tr("Localizable", "SOL was sent to Moonpay and is being processed. Any questions regarding your transaction can be answered via") }
  }

  internal enum SaveThatSeedPhraseAndKeepItInTheSafePlace {
    /// Save that seed phrase and keep it in the safe place. Will be used for recovery and backup.
    internal static var willBeUsedForRecoveryAndBackup: String { L10n.tr("Localizable", "Save that seed phrase and keep it in the safe place. Will be used for recovery and backup.") }
  }

  internal enum SecurityKeyCanTBeSavedIntoIcloud {
    /// Security key can't be saved into icloud. Please try again.
    internal static var pleaseTryAgain: String { L10n.tr("Localizable", "Security key can't be saved into icloud. Please try again.") }
  }

  internal enum SeedPhraseIsTheOnlyWayToAccessYourFundsOnAnotherDevice {
    /// Seed phrase is the only way to access your funds on another device. Key App doesn't have access to this information.
    internal static var keyAppDoesnTHaveAccessToThisInformation: String { L10n.tr("Localizable", "Seed phrase is the only way to access your funds on another device. Key App doesn't have access to this information.") }
  }

  internal enum SendBTCETHUSDCWithNoFees {
    /// Send BTC, ETH, USDC with no fees.\nSwap BTC with only $1
    internal static var swapBTCWithOnly1: String { L10n.tr("Localizable", "Send BTC, ETH, USDC with no fees. Swap BTC with only $1") }
  }

  internal enum SendingYourDepositToSolend {
    /// Sending your deposit to Solend. Just wait\nuntil it’s done
    internal static var justWaitUntilItSDone: String { L10n.tr("Localizable", "Sending your deposit to Solend. Just wait\nuntil it’s done") }
  }

  internal enum SlippageRefersToTheDifferenceBetweenTheExpectedPriceOfATradeAndThePriceAtWhichTheTradeIsExecuted {
    /// Slippage refers to the difference between the expected price of a trade and the price at which the trade is executed. Slippage can occur at any time but is most prevalent during periods of higher volatility when market orders are used.
    internal static var slippageCanOccurAtAnyTimeButIsMostPrevalentDuringPeriodsOfHigherVolatilityWhenMarketOrdersAreUsed: String { L10n.tr("Localizable", "Slippage refers to the difference between the expected price of a trade and the price at which the trade is executed. Slippage can occur at any time but is most prevalent during periods of higher volatility when market orders are used.") }
  }

  internal enum SolanaAssociatedTokenAccountRequired {
    /// Solana Associated Token Account Required. This will require you to sign a transaction and spend some SOL.
    internal static var thisWillRequireYouToSignATransactionAndSpendSomeSOL: String { L10n.tr("Localizable", "Solana Associated Token Account Required. This will require you to sign a transaction and spend some SOL.") }
  }

  internal enum SomethingWentWrong {
    /// Something went wrong. Please try again
    internal static var pleaseTryAgain: String { L10n.tr("Localizable", "Something went wrong. Please try again") }
  }

  internal enum SomethingWrongWithPhoneNumberOrSettings {
    /// Something wrong with phone number %@ or settings. If you wish to report the issue, use error code #%@
    internal static func ifYouWishToReportTheIssueUseErrorCode(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "Something wrong with phone number %@ or settings. If you wish to report the issue, use error code #%@", String(describing: p1), String(describing: p2))
    }
  }

  internal enum SwapInstructionExceedsDesiredSlippageLimit {
    /// Swap instruction exceeds desired slippage limit.\nSet another slippage and try again.
    internal static var setAnotherSlippageAndTryAgain: String { L10n.tr("Localizable", "Swap instruction exceeds desired slippage limit.\nSet another slippage and try again.") }
  }

  internal enum TheSolanaProgramLibrarySPLIsACollectionOfOnChainProgramsMaintainedByTheSolanaTeam {
    internal enum TheSPLTokenProgramIsTheTokenStandardOfTheSolanaBlockchain {
      /// The Solana Program Library (SPL) is a collection of on-chain programs maintained by the Solana team. The SPL Token program is the token standard of the Solana blockchain.\n\nSimilar to ERC-20 tokens on the Ethereum network, SPL Tokens are designed for DeFi applications.
      internal static var similarToERC20TokensOnTheEthereumNetworkSPLTokensAreDesignedForDeFiApplications: String { L10n.tr("Localizable", "The Solana Program Library (SPL) is a collection of on-chain programs maintained by the Solana team. The SPL Token program is the token standard of the Solana blockchain.\n\nSimilar to ERC20 tokens on the Ethereum network, SPL Tokens are designed for DeFi applications.") }
    }
  }

  internal enum TheBankHasSeenThisTransactionBefore {
    /// The bank has seen this transaction before. This can occur under normal operation when a UDP packet is duplicated, as a user error from a client not updating its %@, or as a double-spend attack.
    internal static func thisCanOccurUnderNormalOperationWhenAUDPPacketIsDuplicatedAsAUserErrorFromAClientNotUpdatingItsOrAsADoubleSpendAttack(_ p1: Any) -> String {
      return L10n.tr("Localizable", "The bank has seen this transaction before. This can occur under normal operation when a UDP packet is duplicated, as a user error from a client not updating its %@, or as a double-spend attack.", String(describing: p1))
    }
  }

  internal enum TheDataIsBeingUpdated {
    /// The data is being updated. Please try again in a few minutes.
    internal static var pleaseTryAgainInAFewMinutes: String { L10n.tr("Localizable", "The data is being updated. Please try again in a few minutes.") }
  }

  internal enum TheFollowingWordsAreTheSecurityKeyThatYouMustKeepInASafePlaceWrittenInTheCorrectSequence {
    internal enum IfLostNoOneCanRestoreIt {
      /// The following words are the security key that you must keep in a safe place, written in the correct sequence.\n\nIf lost, no one can restore it.\nKeep it private, even from us
      internal static var keepItPrivateEvenFromUs: String { L10n.tr("Localizable", "The following words are the security key that you must keep in a safe place, written in the correct sequence.\nIf lost, no one can restore it.\nKeep it private, even from us") }
    }
  }

  internal enum TheFundsAreReturnedToYourWallet {
    /// The funds are returned to your wallet. You can try depositing again.
    internal static var youCanTryDepositingAgain: String { L10n.tr("Localizable", "The funds are returned to your wallet. You can try depositing again.") }
  }

  internal enum TheLinkWorksOnly1TimeForAnyUsers {
    /// The link works only 1 time for any users.\nIf you log in yourself, the funds will be returned to your account
    internal static var ifYouLogInYourselfTheFundsWillBeReturnedToYourAccount: String { L10n.tr("Localizable", "The link works only 1 time for any users.\nIf you log in yourself, the funds will be returned to your account") }
  }

  internal enum TheMinimumAmountYouWillReceive {
    /// The minimum amount you will receive. If the price slips any further, your transaction will revert.
    internal static var ifThePriceSlipsAnyFurtherYourTransactionWillRevert: String { L10n.tr("Localizable", "The minimum amount you will receive. If the price slips any further, your transaction will revert.") }
  }

  internal enum TheOneTimeLinkCanBeUsedToSendFundsToAnyoneWithoutNeedingAnAddress {
    /// The one-time link can be used to send funds to anyone without needing an address. The funds can be claimed by anyone with a link.
    internal static var theFundsCanBeClaimedByAnyoneWithALink: String { L10n.tr("Localizable", "The one-time link can be used to send funds to anyone without needing an address. The funds can be claimed by anyone with a link.") }
  }

  internal enum ThePriceIsHigherBecauseOfYourTradeSize {
    /// The price is higher because of your trade size. Consider splitting your transaction into multiple swaps.
    internal static var considerSplittingYourTransactionIntoMultipleSwaps: String { L10n.tr("Localizable", "The price is higher because of your trade size. Consider splitting your transaction into multiple swaps.") }
  }

  internal enum TheSeedPhraseDoesnTMatch {
    /// The seed phrase doesn't match. Please try again
    internal static var pleaseTryAgain: String { L10n.tr("Localizable", "The seed phrase doesn't match. Please try again") }
  }

  internal enum TheTransactionWasRejected {
    /// The transaction was rejected. Open your link again.
    internal static var openYourLinkAgain: String { L10n.tr("Localizable", "The transaction was rejected. Open your link again.") }
  }

  internal enum TheTransactionWasRejectedAfterFailedInternetConnection {
    /// The transaction was rejected after failed internet connection. Open your link again
    internal static var openYourLinkAgain: String { L10n.tr("Localizable", "The transaction was rejected after failed internet connection. Open your link again") }
  }

  internal enum TheWordsInYourSecurityKeyNeedToBeSelectedInTheRightOrder {
    /// The words in your security key need to be selected in the right order. Alternatively, you can make an iCloud backup
    internal static var alternativelyYouCanMakeAnICloudBackup: String { L10n.tr("Localizable", "The words in your security key need to be selected in the right order. Alternatively, you can make an iCloud backup") }
  }

  internal enum TheWrongSecurityKeyOrWordsOrder {
    /// The wrong security key or words order. Please try again
    internal static var pleaseTryAgain: String { L10n.tr("Localizable", "The wrong security key or words order. Please try again") }
  }

  internal enum ThereIsAProblemWithServices {
    /// There is a problem with %@ Services. Try again
    internal static func tryAgain(_ p1: Any) -> String {
      return L10n.tr("Localizable", "There is a problem with %@ Services. Try again", String(describing: p1))
    }
  }

  internal enum ThereIsAnErrorOccurred {
    /// There is an error occurred. You can either retry or reserve name later in Settings
    internal static var youCanEitherRetryOrReserveNameLaterInSettings: String { L10n.tr("Localizable", "There is an error occurred. You can either retry or reserve name later in Settings") }
  }

  internal enum ThereWasAProblemWithClaiming {
    /// There was a problem with claiming. Please try again
    internal static var pleaseTryAgain: String { L10n.tr("Localizable", "There was a problem with claiming. Please try again") }
  }

  internal enum ThereWasAProblemWithSending {
    /// There was a problem with sending. Please try again
    internal static var pleaseTryAgain: String { L10n.tr("Localizable", "There was a problem with sending. Please try again") }
  }

  internal enum ThereSAProblemShowingTheRates {
    /// There’s a problem showing the rates.\nTry again later
    internal static var tryAgainLater: String { L10n.tr("Localizable", "There’s a problem showing the rates.\nTry again later") }
  }

  internal enum ThisAccountIsAssociatedWith {
    /// This account is associated with %@. Please log in with the correct %@ ID.
    internal static func pleaseLogInWithTheCorrectID(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "This account is associated with %@. Please log in with the correct %@ ID.", String(describing: p1), String(describing: p2))
    }
  }

  internal enum ThisAddressAccepts {
    /// This address accepts %@. You may lose assets by sending another coin.
    internal static func youMayLoseAssetsBySendingAnotherCoin(_ p1: Any) -> String {
      return L10n.tr("Localizable", "This address accepts %@. You may lose assets by sending another coin.", String(describing: p1))
    }
  }

  internal enum ThisAddressAcceptsOnly {
    /// This address accepts **only %@**. You may lose assets by sending another coin.
    internal static func youMayLoseAssetsBySendingAnotherCoin(_ p1: Any) -> String {
      return L10n.tr("Localizable", "This address accepts only %@. You may lose assets by sending another coin.", String(describing: p1))
    }
  }

  internal enum ThisAddressDoesNotAppearToHaveAAccount {
    internal enum YouHaveToPayAOneTimeFeeToCreateAAccountForThisAddress {
      /// This address does not appear to have a %@ account. You have to pay a one-time fee to create a %@ account for this address. You can choose which currency to pay in below.
      internal static func youCanChooseWhichCurrencyToPayInBelow(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "This address does not appear to have a %@ account. You have to pay a one-time fee to create a %@ account for this address. You can choose which currency to pay in below.", String(describing: p1), String(describing: p2))
      }
    }
  }

  internal enum ThisAddressHasNoFunds {
    /// This address has no funds. Are you sure it's correct?
    internal static var areYouSureItSCorrect: String { L10n.tr("Localizable", "This address has no funds. Are you sure it's correct?") }
  }

  internal enum ThisAppDoesNotHavePermissionToUseYourCameraForScanningQrCode {
    /// This app does not have permission to use your camera for scanning Qr Code. Please enable it in settings!
    internal static var pleaseEnableItInSettings: String { L10n.tr("Localizable", "This app does not have permission to use your camera for scanning Qr Code. Please enable it in settings!") }
  }

  internal enum ThisIsTheThingYouUseToGetAllYourAccountsFromYourMnemonicPhrase {
    /// This is the thing you use to get all your accounts from your mnemonic phrase. By default, Key App will use m/44'/501'/0'/0' as the derivation path for the main wallet.
    internal static var byDefaultKeyAppWillUseM4450100AsTheDerivationPathForTheMainWallet: String { L10n.tr("Localizable", "This is the thing you use to get all your accounts from your mnemonic phrase. By default, Key App will use m/44'/501'/0'/0' as the derivation path for the main wallet.") }
  }

  internal enum ThisPhoneHasAlreadyBeenConfirmed {
    /// This phone has already been confirmed. Change phone number
    internal static var changePhoneNumber: String { L10n.tr("Localizable", "This phone has already been confirmed. Change phone number") }
  }

  internal enum TokenNotFound {
    /// Token not found. Try another one
    internal static var tryAnotherOne: String { L10n.tr("Localizable", "Token not found. Try another one") }
  }

  internal enum TokenRatesAreUnavailable {
    /// Token rates are unavailable. Everything works as usual and all funds are safe.
    internal static var everythingWorksAsUsualAndAllFundsAreSafe: String { L10n.tr("Localizable", "Token rates are unavailable. Everything works as usual and all funds are safe.") }
  }

  internal enum UsernameIsYourPublicAddressWhichAllowsYouToReceiveAnyTokenEvenIfYouDonTHaveItInTheWalletList {
    /// Username is your public address, which allows you to receive any token even if you don't have it in the wallet list.\n\nIt is vital you select the exact username you want, as once set, you cannot change it.
    internal static var itIsVitalYouSelectTheExactUsernameYouWantAsOnceSetYouCannotChangeIt: String { L10n.tr("Localizable", "Username is your public address, which allows you to receive any token even if you don't have it in the wallet list.\n\nIt is vital you select the exact username you want, as once set, you cannot change it.") }
  }

  internal enum WeCouldnTUploadTheHistory {
    /// We couldn't upload the history.\nTry again later
    internal static var tryAgainLater: String { L10n.tr("Localizable", "We couldn't upload the history.\nTry again later") }
  }

  internal enum WeCouldnTAddATokenToYourWallet {
    /// We couldn’t add a token to your wallet.\nCheck your internet connection and try again.
    internal static var checkYourInternetConnectionAndTryAgain: String { L10n.tr("Localizable", "We couldn’t add a token to your wallet.\nCheck your internet connection and try again.") }
  }

  internal enum WeProvideYouWithThePossibilityToUseSecureAndTrustedProtocols {
    /// We provide you with the possibility to use secure and trusted protocols. Deposit USDT and USDC to earn interest
    internal static var depositUSDTAndUSDCToEarnInterest: String { L10n.tr("Localizable", "We provide you with the possibility to use secure and trusted protocols. Deposit USDT and USDC to earn interest") }
  }

  internal enum WeVeBrokeSomethingReallyBig {
    internal enum LetSWaitTogetherFinallyTheAppWillBeRepaired {
      /// We’ve broke something really big.\nLet’s wait together, finally the app will be repaired.\n\nIf you wish to report the issue, use error code #%@
      internal static func ifYouWishToReportTheIssueUseErrorCode(_ p1: Any) -> String {
        return L10n.tr("Localizable", "We’ve broke something really big.\nLet’s wait together, finally the app will be repaired.\n\nIf you wish to report the issue, use error code #%@", String(describing: p1))
      }
    }
  }

  internal enum WhenYouChooseTheBitcoinNetworkYourAddressAcceptsOnlyBitcoin {
    internal enum YouMayLoseAssetsBySendingAnotherCoin {
      internal enum _0 {
        /// When you choose the Bitcoin network, your address accepts only Bitcoin. You may lose assets by sending another coin.\n\n0.000112 BTC is the minimum transaction amount, and you have 36 hours to complete the transaction after receiving the address.
        internal static var _000112BTCIsTheMinimumTransactionAmountAndYouHave36HoursToCompleteTheTransactionAfterReceivingTheAddress: String { L10n.tr("Localizable", "When you choose the Bitcoin network, your address accepts only Bitcoin. You may lose assets by sending another coin.\n0.000112 BTC is the minimum transaction amount, and you have 36 hours to complete the transaction after receiving the address.") }
      }
    }
  }

  internal enum WithKeyAppTheFirstTransactionIsFree {
    /// With Key App, the first transaction is free. Also all the transactions above $300 are free
    internal static var alsoAllTheTransactionsAbove300AreFree: String { L10n.tr("Localizable", "With Key App, the first transaction is free. Also all the transactions above $300 are free") }
  }

  internal enum WithdrawingYourFundsFromSolend {
    /// Withdrawing your funds from Solend. Just\nwait until it’s done
    internal static var justWaitUntilItSDone: String { L10n.tr("Localizable", "Withdrawing your funds from Solend. Just\nwait until it’s done") }
  }

  internal enum WormholeBridgeIsCurrentlyUnable {
    /// Wormhole Bridge is currently unable.\nPlease try again later
    internal static var pleaseTryAgainLater: String { L10n.tr("Localizable", "Wormhole Bridge is currently unable.\nPlease try again later") }
  }

  internal enum WriteDownOrDuplicateTheseWordsInTheCorrectOrderAndKeepThemInASafePlace {
    /// Write down or duplicate these words in the correct order and keep them in a safe place.\nCopy them manually or backup to iCloud
    internal static var copyThemManuallyOrBackupToICloud: String { L10n.tr("Localizable", "Write down or duplicate these words in the correct order and keep them in a safe place.\nCopy them manually or backup to iCloud") }
  }

  internal enum YouAreTryingToDepositMoreFundsThanPossible {
    /// You are trying to deposit more funds than possible. If you want to deposit the maximum amount, press “Deposit MAX amount”.
    internal static var ifYouWantToDepositTheMaximumAmountPressDepositMAXAmount: String { L10n.tr("Localizable", "You are trying to deposit more funds than possible. If you want to deposit the maximum amount, press “Deposit MAX amount”.") }
  }

  internal enum YouCanNotSwapToItself {
    /// You can not swap %@ to itself.\nPlease choose another token
    internal static func pleaseChooseAnotherToken(_ p1: Any) -> String {
      return L10n.tr("Localizable", "You can not swap %@ to itself.\nPlease choose another token", String(describing: p1))
    }
  }

  internal enum YouDidnTFinishYourCashOutTransaction {
    internal enum After7DaysYourTransactionHasBeenAutomaticallyDeclined {
      /// You didn't finish your cash out transaction. After 7 days your transaction has been automatically declined.\n\nYou can try again, but your new transaction will be subject to the current rates.
      internal static var youCanTryAgainButYourNewTransactionWillBeSubjectToTheCurrentRates: String { L10n.tr("Localizable", "You didn't finish your cash out transaction. After 7 days your transaction has been automatically declined.\n\nYou can try again, but your new transaction will be subject to the current rates.") }
    }
  }

  internal enum YouHaveAttemptsLeftToTypeTheCorrectPIN {
    /// You have %@ attempts left to type the correct PIN.\nReset the PIN or wait for %@.
    internal static func resetThePINOrWaitFor(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "You have %@ attempts left to type the correct PIN.\nReset the PIN or wait for %@.", String(describing: p1), String(describing: p2))
    }
  }

  internal enum YouHaveAGreatStartWith {
    /// You have a great start with %@. It’s only a PIN needed  to create a new wallet
    internal static func itSOnlyAPINNeededToCreateANewWallet(_ p1: Any) -> String {
      return L10n.tr("Localizable", "You have a great start with %@. It’s only a PIN needed  to create a new wallet", String(describing: p1))
    }
    /// You have a great start with %@. Only a phone number is needed to create a new wallet.
    internal static func onlyAPhoneNumberIsNeededToCreateANewWallet(_ p1: Any) -> String {
      return L10n.tr("Localizable", "You have a great start with %@. Only a phone number is needed to create a new wallet.", String(describing: p1))
    }
  }

  internal enum YouHaveReachedTheDailyLimitOfSendingFreeLinks {
    /// You have reached the daily limit of sending free links. Try tomorrow
    internal static var tryTomorrow: String { L10n.tr("Localizable", "You have reached the daily limit of sending free links. Try tomorrow") }
  }

  internal enum YouRequestOTPTooOften {
    /// You request OTP too often. Try later.
    internal static var tryLater: String { L10n.tr("Localizable", "You request OTP too often. Try later.") }
  }

  internal enum YouUsed5IncorrectCodes {
    /// You used 5 incorrect codes.\nFor your safety, we have frozen your account for %@
    internal static func forYourSafetyWeHaveFrozenYourAccountFor(_ p1: Any) -> String {
      return L10n.tr("Localizable", "You used 5 incorrect codes.\nFor your safety, we have frozen your account for %@", String(describing: p1))
    }
  }

  internal enum YouUsedTooMuchNumbers {
    /// You used too much numbers.\nFor your safety we stoped actions for %@
    internal static func forYourSafetyWeStopedActionsFor(_ p1: Any) -> String {
      return L10n.tr("Localizable", "You used too much numbers.\nFor your safety we stoped actions for %@", String(describing: p1))
    }
    /// You used too much numbers. For your safety, we have frozen your account for %@
    internal static func forYourSafetyWeHaveFrozenYourAccountFor(_ p1: Any) -> String {
      return L10n.tr("Localizable", "You used too much numbers. For your safety, we have frozen your account for %@", String(describing: p1))
    }
  }

  internal enum YouWillLoseAccessToTheFreeUsernameThatYouReceivedDuringRegistration {
    /// You will lose access to the free username that you received during registration. Your friends will not be able to send you funds using your username.
    internal static var yourFriendsWillNotBeAbleToSendYouFundsUsingYourUsername: String { L10n.tr("Localizable", "You will lose access to the free username that you received during registration. Your friends will not be able to send you funds using your username.") }
  }

  internal enum YouVeUsedAll5Codes {
    internal enum TryAgainIn {
      /// You've used all 5 codes. Try again in %@. For help, contact support.
      internal static func forHelpContactSupport(_ p1: Any) -> String {
        return L10n.tr("Localizable", "You've used all 5 codes. Try again in %@. For help, contact support.", String(describing: p1))
      }
    }
    internal enum TryAgainLater {
      /// You've used all 5 codes. Try again later. For help, contact support.
      internal static var forHelpContactSupport: String { L10n.tr("Localizable", "You've used all 5 codes. Try again later. For help, contact support.") }
    }
  }

  internal enum YourAddressWillBeDisabled {
    /// Your %@ address will be disabled. This action can not be undone
    internal static func thisActionCanNotBeUndone(_ p1: Any) -> String {
      return L10n.tr("Localizable", "Your %@ address will be disabled. This action can not be undone", String(describing: p1))
    }
  }

  internal enum YourWalletHasNotBeenCreatedYet {
    /// Your %@ wallet has not been created yet.\nBut you can receive %@ by using your SOL wallet's address below
    internal static func butYouCanReceiveByUsingYourSOLWalletSAddressBelow(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "Your %@ wallet has not been created yet.\nBut you can receive %@ by using your SOL wallet's address below", String(describing: p1), String(describing: p2))
    }
  }

  internal enum YourBalanceWillBeConvertedAndTransferredToYourMainSOLWalletAndYourAddressWillBeDisabled {
    /// Your balance will be converted and transferred to your main SOL wallet and your %@ address will be disabled. This action can not be undone.
    internal static func thisActionCanNotBeUndone(_ p1: Any) -> String {
      return L10n.tr("Localizable", "Your balance will be converted and transferred to your main SOL wallet and your %@ address will be disabled. This action can not be undone.", String(describing: p1))
    }
  }

  internal enum YourDeviceDoesNotSupportScanningACodeFromAnItem {
    /// Your device does not support scanning a code from an item. Please use a device with a camera.
    internal static var pleaseUseADeviceWithACamera: String { L10n.tr("Localizable", "Your device does not support scanning a code from an item. Please use a device with a camera.") }
  }

  internal enum YourHistoryWillAppearHere {
    /// Your history will appear here.\nTo get started you can:
    internal static var toGetStartedYouCan: String { L10n.tr("Localizable", "Your history will appear here.\nTo get started you can:") }
  }

  internal enum YourPrivateKeyIsSplitIntoMultipleFactors {
    internal enum AtLeastYouShouldHaveThreeFactorsButYouCanCreateMore {
      /// Your private key is split into multiple factors. At least, you should have three factors, but you can create more. To log in to different devices, you need at least two factors.
      internal static var toLogInToDifferentDevicesYouNeedAtLeastTwoFactors: String { L10n.tr("Localizable", "Your private key is split into multiple factors. At least, you should have three factors, but you can create more. To log in to different devices, you need at least two factors.") }
    }
  }

  internal enum YouReGoingToCreateAPublicBitcoinAddressThatWillBeValidForTheNext24Hours {
    /// You’re going to create a public Bitcoin address that will be valid for the next **24 hours**. You still can hold and send Bitcoin without restrictions.
    internal static var youStillCanHoldAndSendBitcoinWithoutRestrictions: String { L10n.tr("Localizable", "You’re going to create a public Bitcoin address that will be valid for the next **24 hours**. You still can hold and send Bitcoin without restrictions.") }
  }

  internal enum YouVeFindASeldonPage {
    internal enum ItSLikeAUnicornButCrush {
      /// You’ve find a seldon page.\nIt’s like a unicorn, but crush. We’re already fixing it
      internal static var weReAlreadyFixingIt: String { L10n.tr("Localizable", "You’ve find a seldon page.\nIt’s like a unicorn, but crush. We’re already fixing it") }
    }
  }

  internal enum YouVeFindASeldonPage🦄ItSLikeAUnicornButItSACrush {
    internal enum WeReAlreadyFixingIt {
      /// You’ve find a seldon page 🦄 It’s like a unicorn, but it’s a crush. We’re already fixing it. If you wish to report the issue, use error code #%@
      internal static func ifYouWishToReportTheIssueUseErrorCode(_ p1: Any) -> String {
        return L10n.tr("Localizable", "You’ve find a seldon page 🦄 It’s like a unicorn, but it’s a crush. We’re already fixing it. If you wish to report the issue, use error code #%@", String(describing: p1))
      }
    }
  }

  internal enum ICloudRestoreIsForReturningUsers {
    /// iCloud restore is for returning users.\nPasting the security key manually is for everyone
    internal static var pastingTheSecurityKeyManuallyIsForEveryone: String { L10n.tr("Localizable", "iCloud restore is for returning users.\nPasting the security key manually is for everyone") }
  }

  internal enum SelectPhoneNumber {
    /// select phone number. If you made a mistake, please choose another mail
    internal static var ifYouMadeAMistakePleaseChooseAnotherMail: String { L10n.tr("Localizable", "select phone number. If you made a mistake, please choose another mail") }
  }

  internal enum WasTurnedOff {
    /// was turned off.\nDo you want to turn it on?
    internal static var doYouWantToTurnItOn: String { L10n.tr("Localizable", "was turned off.\nDo you want to turn it on?") }
  }

  internal enum 😢PINDoesnTMatch {
    /// 😢 PIN doesn't match. Please try again
    internal static var pleaseTryAgain: String { L10n.tr("Localizable", "😢 PIN doesn't match. Please try again") }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.shared, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
