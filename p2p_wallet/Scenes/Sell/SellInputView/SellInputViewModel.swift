//
//  SellInputViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2022.
//

import Foundation
import Combine

final class SellInputViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Properties
    
    @Published var baseAmount: Double?
    @Published var quoteAmount: Double?
}
