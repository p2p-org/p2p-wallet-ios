final class ChooseRestoreOptionButtonFactory {
    func createMain(for option: RestoreOption) -> ChooseRestoreOptionButton {
        switch option {
        case .keychain:
            return .init(option: .keychain, title: L10n.continueWithICloudKeyChain, icon: UIImage(resource: .cloud))
        case .socialApple:
            return .init(option: .socialApple, title: L10n.continueWithApple, icon: UIImage(resource: .appleLogo))
        case .socialGoogle:
            return .init(option: .socialGoogle, title: L10n.continueWithGoogle, icon: UIImage(resource: .google))
        case .custom:
            return .init(option: .custom, title: L10n.continueUsingPhoneNumber)
        default:
            fatalError("\(option) is not provided as main button currently")
        }
    }

    func createSecondary(for option: RestoreOption) -> ChooseRestoreOptionButton {
        switch option {
        case .custom:
            return .init(option: .custom, title: L10n.continueUsingPhoneNumber)
        case .socialGoogle:
            return .init(option: .socialGoogle, title: L10n.continueWithGoogle)
        case .seed:
            return .init(option: .seed, title: L10n.useASeedPhrase)
        default:
            fatalError("\(option) is not provided as secondary button currently")
        }
    }
}
