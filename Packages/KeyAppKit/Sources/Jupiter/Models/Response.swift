// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public struct Response<T: Codable & Equatable>: Codable, Equatable {
    public let data: T
    public let timeTaken: Double
    public let contextSlot: Int?

    public init(data: T, timeTaken: Double, contextSlot: Int?) {
        self.data = data
        self.timeTaken = timeTaken
        self.contextSlot = contextSlot
    }
}
