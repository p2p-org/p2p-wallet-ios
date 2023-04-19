// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

public struct SecurityData: Codable, Equatable {
    public let pincode: String
    public let isBiometryEnabled: Bool
}
