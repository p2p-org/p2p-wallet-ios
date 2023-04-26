// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

struct UsernameUtils {
    static func splitIntoNameAndDomain(rawName: String) -> (name: String, domain: String) {
        var name = ""
        var domain = ""
        
        let nameComponents: [String] = rawName.components(separatedBy: ".")

        if nameComponents.count > 1 {
            name = nameComponents.prefix(nameComponents.count - 1).joined(separator: ".")
            domain = nameComponents.last ?? ""
        } else {
            name = rawName
        }
        
        return (name: name, domain: domain)
    }
}
