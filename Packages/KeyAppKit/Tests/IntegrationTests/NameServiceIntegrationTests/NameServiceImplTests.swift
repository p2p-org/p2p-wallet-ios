// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import XCTest
@testable import NameService

class NameServiceImplTests: XCTestCase {
    let cache: NameServiceCacheType = TmpCache()
    lazy var service: NameService = NameServiceImpl(
        endpoint: "https://name-register.key.app",
        cache: cache
    )

    func testGetName() async throws {
        let name = try await service.getName("9RvNi4pPm8euMuPGPNQVjR8wWTPawZMvqfqA2QQmwVHC")
        XCTAssertEqual(name, "amarannta-test")

        let cachedValue = try await service.getName("9RvNi4pPm8euMuPGPNQVjR8wWTPawZMvqfqA2QQmwVHC")
        XCTAssertEqual(cachedValue, "amarannta-test")
    }

    func testGetOwnerAddress() async throws {
        let publicKey = try await service.getOwnerAddress("alla")
        XCTAssertEqual(publicKey, "6PvJNsAoKJiyEaHEdFg3qEMGjWgR7tR6UmXi2imfPZS7")
    }

    func testGetOwnerFailedAddress() async throws {
        let publicKey = try await service.getOwnerAddress("6PvJNsAoKJiyEaHEdFg3qEMGjWgR7tR6UmXi2imfPZS6")
        XCTAssertNil(publicKey)
    }

    func testGetOwners() async throws {
        let publicKeys = try await service.getOwners("kirill")
        XCTAssertTrue(!publicKeys.isEmpty)
    }

    func testGetOwnersNotFound() async throws {
        let publicKeys = try await service.getOwners("zzzzzzzzzzzzzzzzzzzzz")
        XCTAssertTrue(publicKeys.isEmpty)
    }
}

class TmpCache: NameServiceCacheType {
    private var data: [String: String] = [:]

    func save(_ name: String?, for owner: String) {
        guard let name = name else { return }
        data[owner] = name
    }

    func getName(for owner: String) -> NameServiceSearchResult? {
        if let r = data[owner] {
            return .registered(r)
        }

        return nil
    }
}
