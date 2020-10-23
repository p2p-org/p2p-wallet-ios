//
//  String+Extensions.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/23/20.
//

import Foundation

extension String {
    var firstCharacter: String {
        String(prefix(1))
    }
    public var uppercaseFirst: String {
        firstCharacter.uppercased() + String(dropFirst())
    }
}
