// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

protocol ScreenEvents: MirrorableEnum {
    var screenName: String? { get }
}

extension ScreenEvents {
    var screenName: String? {
        mirror.label.snakeCased()
    }
}
