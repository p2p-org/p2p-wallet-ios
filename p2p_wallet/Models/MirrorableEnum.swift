//
//  MirrorableEnum.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/11/2021.
//

import Foundation

protocol MirrorableEnum {}

extension MirrorableEnum {
    var mirror: (label: String, params: [String: Any]) {
        let reflection = Mirror(reflecting: self)
        guard reflection.displayStyle == .enum,
              let associated = reflection.children.first
        else {
            return ("\(self)", [:])
        }
        let values = Mirror(reflecting: associated.value).children
        var valuesArray = [String: Any]()
        for case let item in values where item.label != nil {
            valuesArray[item.label!] = item.value
        }
        return (associated.label!, valuesArray)
    }
}
