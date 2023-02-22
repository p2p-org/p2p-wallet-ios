//
//  Array+Extensions.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 20.02.2023.
//

import Foundation

enum ListBuilder {
    static func merge<T>(primary: [T], secondary: [T], by id: KeyPath<T, String>) -> [T] {
        let filteredSecondary = secondary.filter { secondaryItem in
            primary.contains { primaryItem in
                primaryItem[keyPath: id] == secondaryItem[keyPath: id]
            }
        }

        return primary + filteredSecondary
    }

    static let defaultDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.shared
        return dateFormatter
    }()

    static func aggregate<T, V>(list: [T], by dateKeyPath: KeyPath<T, Date>, dateFormatter: DateFormatter = ListBuilder.defaultDateFormatter, tranform: (String, [T]) -> V) -> [V] {
        let dictionary = Dictionary(grouping: list) { item -> Date in
            Calendar.current.startOfDay(for: item[keyPath: dateKeyPath])
        }

        return dictionary.keys.sorted().reversed()
            .map { (date: Date) -> V in
                // Sort
                var items = dictionary[date] ?? []
                items.sort { lhs, rhs in
                    lhs[keyPath: dateKeyPath] >= rhs[keyPath: dateKeyPath]
                }
                
                // Date format
                let dateStr: String
                if Calendar.current.isDateInToday(date) {
                    dateStr = L10n.today
                } else if Calendar.current.isDateInYesterday(date) {
                    dateStr = L10n.yesterday
                } else {
                    dateStr = dateFormatter.string(from: date)
                }

                // Tranform
                return tranform(dateStr, items)
            }
    }
}
