// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

enum OnboardingError: Error {
    case invalidValue(at: String)
    case encodingError(String)
    case decodingError(String)
}
