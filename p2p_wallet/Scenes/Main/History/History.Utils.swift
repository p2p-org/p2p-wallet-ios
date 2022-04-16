//
// Created by Giang Long Tran on 12.04.2022.
//

import Foundation

/// The protocol describes ability of class to caching
protocol Cachable {
    /// Clear all cache
    func clear()
}

/// The protocol describes a cache storage
protocol Caching {
    associatedtype Element

    /// Read element from cache
    func read(key: String) -> Element?

    /// Write element from cache
    func write(key: String, data: Element)

    /// Clear all data in cache
    func clear()
}

extension History {
    enum Utils {
        /// Simple cache storage
        class Cache<T>: Caching {
            typealias Element = T

            private let maxSize: Int

            var keysOrder: [String] = []
            var storage: [String: Element] = [:]

            init(maxSize: Int) { self.maxSize = maxSize }

            func read(key: String) -> Element? {
                if keysOrder.contains(key) { return storage[key] }
                return nil
            }

            func write(key: String, data: Element) {
                keysOrder.append(key)
                storage[key] = data
                check()
            }

            /// Free the resource if cache storage has reached a limit.
            private func check() {
                while keysOrder.count > maxSize {
                    let key = keysOrder.remove(at: 0)
                    storage.removeValue(forKey: key)
                }
            }

            func clear() {
                keysOrder = []
                storage = [:]
            }
        }

        /// This class help to track and analyse caching process.
        class TrackingCache<T>: Caching {
            typealias Element = T

            private let delegate: Cache<T>
            private var hit: Int = 0
            private var total: Int = 0

            init(delegate: Cache<T>) { self.delegate = delegate }

            func read(key: String) -> T? { record(element: delegate.read(key: key)) }

            func write(key: String, data: T) { delegate.write(key: key, data: data) }

            func clear() { delegate.clear() }

            /// Records reading process.
            private func record(element: T?) -> T? {
                total += 1
                if element != nil { hit += 1 }

                return element
            }

            /// Shows to console the statistic.
            func summarize() {
                debugPrint("Summarize cache:")
                debugPrint("Hit: ", hit)
                debugPrint("Total: ", total)
                if total > 0 { debugPrint("Coefficient: ", Double(hit) / Double(total)) }
            }
        }
    }
}
