import Foundation
import SolanaSwift

protocol ChangeLanguageResponder {
    func languageDidChange(to: LocalizedLanguage)
}

protocol ChangeNetworkResponder {
    func changeAPIEndpoint(to endpoint: APIEndPoint)
}

protocol ChangeThemeResponder {
    func changeThemeTo(_ style: UIUserInterfaceStyle)
}
