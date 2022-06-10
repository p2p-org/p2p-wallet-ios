// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Plist Files

// swiftlint:disable identifier_name line_length type_body_length
public enum PlistFiles {
    private static let _document = PlistDocument(path: "Info.plist")

    public static let amplitudeApiKey: String = _document["AMPLITUDE_API_KEY"]
    public static let cfBundleDevelopmentRegion: String = _document["CFBundleDevelopmentRegion"]
    public static let cfBundleExecutable: String = _document["CFBundleExecutable"]
    public static let cfBundleIdentifier: String = _document["CFBundleIdentifier"]
    public static let cfBundleInfoDictionaryVersion: String = _document["CFBundleInfoDictionaryVersion"]
    public static let cfBundleName: String = _document["CFBundleName"]
    public static let cfBundlePackageType: String = _document["CFBundlePackageType"]
    public static let cfBundleShortVersionString: String = _document["CFBundleShortVersionString"]
    public static let cfBundleVersion: String = _document["CFBundleVersion"]
    public static let cryptoCompareApiKey: String = _document["CRYPTO_COMPARE_API_KEY"]
    public static let defaultFf: String = _document["DEFAULT_FF"]
    public static let feeRelayerEndpoint: String = _document["FEE_RELAYER_ENDPOINT"]
    public static let lsRequiresIPhoneOS: Bool = _document["LSRequiresIPhoneOS"]
    public static let moonpayProductionApiKey: String = _document["MOONPAY_PRODUCTION_API_KEY"]
    public static let moonpayStagingApiKey: String = _document["MOONPAY_STAGING_API_KEY"]
    public static let nsAppTransportSecurity: [String: Any] = _document["NSAppTransportSecurity"]
    public static let nsCameraUsageDescription: String = _document["NSCameraUsageDescription"]
    public static let nsFaceIDUsageDescription: String = _document["NSFaceIDUsageDescription"]
    public static let nsPhotoLibraryAddUsageDescription: String = _document["NSPhotoLibraryAddUsageDescription"]
    public static let nsPhotoLibraryUsageDescription: String = _document["NSPhotoLibraryUsageDescription"]
    public static let rpcpoolApiKey: String = _document["RPCPOOL_API_KEY"]
    public static let testAccountSeedPhrase: String = _document["TEST_ACCOUNT_SEED_PHRASE"]
    public static let transakHostUrl: String = _document["TRANSAK_HOST_URL"]
    public static let transakProductionApiKey: String = _document["TRANSAK_PRODUCTION_API_KEY"]
    public static let transakStagingApiKey: String = _document["TRANSAK_STAGING_API_KEY"]
    public static let uiAppFonts: [String] = _document["UIAppFonts"]
    public static let uiApplicationSupportsIndirectInputEvents: Bool =
        _document["UIApplicationSupportsIndirectInputEvents"]
    public static let uiLaunchStoryboardName: String = _document["UILaunchStoryboardName"]
    public static let uiRequiredDeviceCapabilities: [String] = _document["UIRequiredDeviceCapabilities"]
    public static let uiRequiresFullScreen: Bool = _document["UIRequiresFullScreen"]
    public static let uiStatusBarStyle: String = _document["UIStatusBarStyle"]
    public static let uiSupportedInterfaceOrientations: [String] = _document["UISupportedInterfaceOrientations"]
    public static let uiSupportedInterfaceOrientationsIpad: [String] =
        _document["UISupportedInterfaceOrientations~ipad"]
    public static let uiUserInterfaceStyle: String = _document["UIUserInterfaceStyle"]
    public static let uiViewControllerBasedStatusBarAppearance: Bool =
        _document["UIViewControllerBasedStatusBarAppearance"]
}

// swiftlint:enable identifier_name line_length type_body_length

// MARK: - Implementation Details

private func arrayFromPlist<T>(at path: String) -> [T] {
    guard let url = BundleToken.bundle.url(forResource: path, withExtension: nil),
          let data = NSArray(contentsOf: url) as? [T]
    else {
        fatalError("Unable to load PLIST at path: \(path)")
    }
    return data
}

private struct PlistDocument {
    let data: [String: Any]

    init(path: String) {
        guard let url = BundleToken.bundle.url(forResource: path, withExtension: nil),
              let data = NSDictionary(contentsOf: url) as? [String: Any]
        else {
            fatalError("Unable to load PLIST at path: \(path)")
        }
        self.data = data
    }

    subscript<T>(key: String) -> T {
        guard let result = data[key] as? T else {
            fatalError("Property '\(key)' is not of type \(T.self)")
        }
        return result
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
