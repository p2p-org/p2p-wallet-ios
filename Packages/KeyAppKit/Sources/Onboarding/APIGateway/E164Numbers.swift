// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum E164Numbers {
    public static func validate(_ input: String) -> Bool {
        let regex = #"^\+[1-9]\d{1,14}$"#
        return (input.range(of: regex, options: .regularExpression)) != nil
    }
}
