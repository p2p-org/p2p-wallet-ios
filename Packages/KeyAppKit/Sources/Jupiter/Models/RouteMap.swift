// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public struct RouteMap: Codable, Equatable {
    public let mintKeys: [String]
    public let indexesRouteMap: [String: [String]]

    public init(mintKeys: [String], indexesRouteMap: [String : [String]]) {
        self.mintKeys = mintKeys
        self.indexesRouteMap = indexesRouteMap
    }
}
