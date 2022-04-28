//
// Created by Giang Long Tran on 12.04.2022.
//

import Foundation

/// The protocol describes a cache storage
protocol Caching {
    associatedtype Element

    /// Read element from cache
    func read(key: String) async -> Element?

    /// Write element from cache
    func write(key: String, data: Element) async

    /// Clear all data in cache
    func clear() async
}

extension History {
    enum Utils {
        /// Simple cache storage
        actor InMemoryCache<T>: Caching {
            typealias Element = T

            private let maxSize: Int

            var keysOrder: [String] = []
            var storage: [String: Element] = [:]

            init(maxSize: Int) { self.maxSize = maxSize }

            func read(key: String) async -> Element? {
                if keysOrder.contains(key) { return storage[key] }
                return nil
            }

            func write(key: String, data: Element) async {
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

            func clear() async {
                keysOrder = []
                storage = [:]
            }
        }

        /// This class help to track and analyse caching process.
        class TrackingCache<T>: Caching {
            typealias Element = T

            private let delegate: InMemoryCache<T>
            private var hit: Int = 0
            private var total: Int = 0

            init(delegate: InMemoryCache<T>) { self.delegate = delegate }

            func read(key: String) async -> T? { await record(element: delegate.read(key: key)) }

            func write(key: String, data: T) async { await delegate.write(key: key, data: data) }

            func clear() async { await delegate.clear() }

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
