//
//  IStrigaProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 15.05.2023.
//

import Foundation

protocol IStrigaProvider: AnyObject {
    func verifyMobileNumber(userId: String, verificationCode: String) async throws
}
