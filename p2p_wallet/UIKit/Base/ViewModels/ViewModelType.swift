//
//  ViewModelType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import Foundation

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    var input: Input {get}
    var output: Output {get}
}
