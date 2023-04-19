// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public typealias None = Void

public class Wrapper<T: Codable & Equatable>: Codable, Equatable {
    public internal(set) var value: T

    internal init(_ value: T) { self.value = value }

    public static func == (lhs: Wrapper<T>, rhs: Wrapper<T>) -> Bool {
        lhs.value == rhs.value
    }
}
