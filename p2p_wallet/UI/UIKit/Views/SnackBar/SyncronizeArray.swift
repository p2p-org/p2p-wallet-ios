import Foundation

class SynchronizedArray<T> {
    private var array: [T] = []
    private let accessQueue = DispatchQueue(label: "org.p2p.keyappui.syncronizeArray", attributes: .concurrent)

    func append(_ newElement: T) {
        accessQueue.async(qos: .default, flags: .barrier) {
            self.array.append(newElement)
        }
    }

    func remove(at index: Int) {
        accessQueue.async(qos: .default, flags: .barrier) {
            self.array.remove(at: index)
        }
    }

    func removeFirst() -> T? {
        var el: T?
        accessQueue.sync {
            let index = 0
            guard self.array.count > index else { return }
            el = self.array[index]
            self.array.remove(at: index)
        }
        return el
    }

    var count: Int {
        var count = 0
        accessQueue.sync {
            count = self.array.count
        }
        return count
    }

    func first() -> T? {
        var element: T?
        accessQueue.sync {
            if !self.array.isEmpty {
                element = self.array[0]
            }
        }

        return element
    }

    subscript(index: Int) -> T {
        set {
            accessQueue.async(qos: .default, flags: .barrier) {
                self.array[index] = newValue
            }
        }
        get {
            var element: T!

            accessQueue.sync {
                element = self.array[index]
            }

            return element
        }
    }
}

extension SynchronizedArray where T: Equatable {
    func remove(element: T) {
        accessQueue.async(qos: .default, flags: .barrier) {
            self.array.removeAll { el in
                el == element
            }
        }
    }
}
