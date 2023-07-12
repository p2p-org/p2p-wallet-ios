import Foundation
import SolanaSwift
import UIKit

protocol AppEventHandlerDelegate: AnyObject {
    func didStartLoading()
    func didStopLoading()
    
    func disablePincodeOnFirstAppear()

    func userDidChangeAPIEndpoint(to endpoint: APIEndPoint)
    func userDidChangeLanguage(to language: LocalizedLanguage)
    func userDidChangeTheme(to theme: UIUserInterfaceStyle)
    func refresh()
}
