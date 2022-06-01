//
//  AppEventHandlerDelegate.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/01/2022.
//

import Foundation
import SolanaSwift

protocol AppEventHandlerDelegate: AnyObject {
    func createWalletDidComplete()
    func restoreWalletDidComplete()

    func onboardingDidFinish(resolvedName: String?)

    func userDidChangeAPIEndpoint(to endpoint: APIEndPoint)
    func userDidChangeLanguage(to language: LocalizedLanguage)
    func userDidLogout()
}
