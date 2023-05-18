// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public protocol Step {
    var step: Float { get }
}

public protocol Continuable {
    var continuable: Bool { get }
}