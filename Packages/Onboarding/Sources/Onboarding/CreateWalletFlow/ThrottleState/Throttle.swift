// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

class Throttle: Codable, Hashable {
    let maxAttempt: Int
    let timeInterval: TimeInterval

    private var attempt: Int = 0
    private var lastTime: Date = .init()

    init(maxAttempt: Int, timeInterval: TimeInterval) {
        self.maxAttempt = maxAttempt
        self.timeInterval = timeInterval
    }

    public func process() -> Bool {
        if lastTime.addingTimeInterval(timeInterval) < Date() {
            attempt = 1
            lastTime = Date()
            return true
        }

        if attempt >= maxAttempt - 1 {
            return false
        }

        if attempt == 0 { lastTime = Date() }

        attempt = attempt + 1
        return true
    }
    
    func reset() {
        attempt = 0
        lastTime = Date()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(maxAttempt)
        hasher.combine(timeInterval)
        hasher.combine(attempt)
        hasher.combine(lastTime)
    }

    static func == (lhs: Throttle, rhs: Throttle) -> Bool {
        if lhs === rhs { return true }
        if type(of: lhs) != type(of: rhs) { return false }
        if lhs.maxAttempt != rhs.maxAttempt { return false }
        if lhs.timeInterval != rhs.timeInterval { return false }
        if lhs.attempt != rhs.attempt { return false }
        if lhs.lastTime != rhs.lastTime { return false }
        return true
    }
}
