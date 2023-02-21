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

    static func aggregate<T, V>(list: [T], by date: KeyPath<T, Date>, dateFormatter: DateFormatter = ListBuilder.defaultDateFormatter, tranform: (String, [T]) -> V) -> [V] {
        let dictionary = Dictionary(grouping: list) { item -> Date in
            Calendar.current.startOfDay(for: item[keyPath: date])
        }

        return dictionary.keys.sorted().reversed()
            .map { key in
                // Sort
                var items = dictionary[key] ?? []
                items.sort { lhs, rhs in
                    lhs[keyPath: date] >= rhs[keyPath: date]
                }

                // Tranform
                return tranform(dateFormatter.string(from: key), items)
            }
    }
}
