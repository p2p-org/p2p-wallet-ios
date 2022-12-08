//
//  SellInputViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2022.
//

import Foundation

final class SellInputViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Properties
    
    @Published var baseAmount: String = ""
    @Published var quoteAmount: String = ""
}
