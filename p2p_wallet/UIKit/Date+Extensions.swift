//
//  Date+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2020.
//

import Foundation

extension Date {
    func string(withFormat format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.shared
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
