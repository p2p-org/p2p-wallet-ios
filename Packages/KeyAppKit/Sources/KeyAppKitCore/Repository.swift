//
//  Repository.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 14.02.2023.
//

import Foundation

public protocol Repository {
    associatedtype Element: Identifiable
    
    func get(id: Element.ID) async throws
}
