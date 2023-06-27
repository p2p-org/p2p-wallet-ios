//
//  DeviceOwnerAuthenticationHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 21/05/2021.
//

import Foundation

// IMPORTANT: DeviceOwnerAuthenticationHandler must be separated from AuthenticationHandler and has to be perform on Root, because at RestoreWallet, there is no passcode.
protocol DeviceOwnerAuthenticationHandler {
    func requiredOwner(onSuccess: (() -> Void)?, onFailure: ((String?) -> Void)?)
}
