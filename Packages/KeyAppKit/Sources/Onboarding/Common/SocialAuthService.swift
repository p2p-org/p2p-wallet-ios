// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

public protocol SocialAuthService {
    func auth(type: SocialProvider) async throws -> (tokenID: String, email: String)
    func isExpired(token: String) -> Bool
}
