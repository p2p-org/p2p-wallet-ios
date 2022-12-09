// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SwiftUI

enum RecipientFormatter {
    private static let maxAddressLength = 6

    static func format(destination: String) -> String {
        if destination.count < maxAddressLength || destination.contains("@") {
            return destination
        } else {
            return "\(destination.prefix(maxAddressLength))...\(destination.suffix(maxAddressLength))"
        }
    }

    static func username(name: String, domain: String) -> String {
        if domain == "key" {
            return "@\(name).\(domain)"
        } else if domain.isEmpty {
            return "\(name)"
        } else {
            return "\(name).\(domain)"
        }
    }
}
