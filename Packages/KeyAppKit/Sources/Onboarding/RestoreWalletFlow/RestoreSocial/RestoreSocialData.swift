// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

public struct RestoreSocialData: Codable, Equatable {
    public let torusKey: TorusKey
    public let email: String
}
