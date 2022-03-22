//
//  CreateOrRestoreWalletHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/01/2022.
//

import Foundation

protocol CreateOrRestoreWalletHandler {
    func creatingWalletDidComplete(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?)
    func restoringWalletDidComplete(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?)
}
