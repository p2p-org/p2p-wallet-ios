//
//  BankTransferState.swift
//  p2p_wallet
//
//  Created by Ivan on 22.05.2023.
//

import Foundation

/// States of bank transfer
enum BankTransferState {
    
    /// Registration hasn't started and bank transfer is enabled
    case notStarted
    
    /// Registration hasn't started and bank transfer isn't enabled
    case notStartedAndNotEnabled
    
    /// Phone number isn't verified
    case phoneNotVerified
    
    /// Bank tranfer is enabled finally
    case phoneVerified
}
