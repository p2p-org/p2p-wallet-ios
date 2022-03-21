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

    static func - (recent: Date, previous: Date) -> (month: Int?, day: Int?, hour: Int?, minute: Int?, second: Int?) {
        let day = Calendar.current.dateComponents([.day], from: previous, to: recent).day
        let month = Calendar.current.dateComponents([.month], from: previous, to: recent).month
        let hour = Calendar.current.dateComponents([.hour], from: previous, to: recent).hour
        let minute = Calendar.current.dateComponents([.minute], from: previous, to: recent).minute
        let second = Calendar.current.dateComponents([.second], from: previous, to: recent).second

        return (month: month, day: day, hour: hour, minute: minute, second: second)
    }
}
