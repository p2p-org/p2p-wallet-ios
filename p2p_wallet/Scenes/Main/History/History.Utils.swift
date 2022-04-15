//
// Created by Giang Long Tran on 12.04.2022.
//

import Foundation

protocol Caching {
    associatedtype Element

    func read(key: String) -> Element?

    func write(key: String, data: Element)

    func clear()
}

extension History {
    enum Utils {
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
    }
}
