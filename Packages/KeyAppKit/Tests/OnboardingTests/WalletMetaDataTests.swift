//
//  WalletMetaDataTests.swift
//
//
//  Created by Giang Long Tran on 29.05.2023.
//

import XCTest
@testable import Onboarding

final class WalletMetaDataTests: XCTestCase {
    func testMerge1() throws {
        let past5SecondsAgo = Date() - 5
        let past15SecondsAgo = Date() - 15
        let current = Date()

        let local = WalletMetaData(
            ethPublic: "123",
            deviceName: "iPhone1",
            deviceNameTimestamp: past5SecondsAgo,
            email: "1@gmail.com",
            emailTimestamp: past15SecondsAgo,
            authProvider: "google",
            authProviderTimestamp: past15SecondsAgo,
            phoneNumber: "12345",
            phoneNumberTimestamp: past15SecondsAgo,
            striga: .init(userIdTimestamp: past15SecondsAgo)
        )

        let remote = WalletMetaData(
            ethPublic: "123",
            deviceName: "iPhone2",
            deviceNameTimestamp: current,
            email: "1@gmail.com",
            emailTimestamp: past15SecondsAgo,
            authProvider: "google",
            authProviderTimestamp: past15SecondsAgo,
            phoneNumber: "12345",
            phoneNumberTimestamp: past15SecondsAgo,
            striga: .init(userIdTimestamp: past15SecondsAgo)
        )

        let mergeDeviceNameResult = WalletMetaData.merge(local, remote, \.deviceName, \.deviceNameTimestamp)
        XCTAssertEqual(mergeDeviceNameResult.0, "iPhone2")
        XCTAssertEqual(mergeDeviceNameResult.1, current)

        let mergeEmailResult = WalletMetaData.merge(local, remote, \.email, \.emailTimestamp)
        XCTAssertEqual(mergeEmailResult.0, "1@gmail.com")
        XCTAssertEqual(mergeEmailResult.1, past15SecondsAgo)
        
        let merged = try WalletMetaData.merge(lhs: local, rhs: remote)
        XCTAssertEqual(remote, merged)
    }
    
    func testMerge2() throws {
        let past5SecondsAgo = Date() - 5
        let past15SecondsAgo = Date() - 15
        let current = Date()

        let local = WalletMetaData(
            ethPublic: "123",
            deviceName: "iPhone1",
            deviceNameTimestamp: past5SecondsAgo,
            email: "1@gmail.com",
            emailTimestamp: past15SecondsAgo,
            authProvider: "google",
            authProviderTimestamp: past15SecondsAgo,
            phoneNumber: "7890",
            phoneNumberTimestamp: past5SecondsAgo,
            striga: .init(userId: "1",userIdTimestamp: past5SecondsAgo)
        )

        let remote = WalletMetaData(
            ethPublic: "123",
            deviceName: "iPhone2",
            deviceNameTimestamp: current,
            email: "1@gmail.com",
            emailTimestamp: past15SecondsAgo,
            authProvider: "google",
            authProviderTimestamp: past15SecondsAgo,
            phoneNumber: "12345",
            phoneNumberTimestamp: past15SecondsAgo,
            striga: .init(userIdTimestamp: past15SecondsAgo)
        )

        let merged = try WalletMetaData.merge(lhs: local, rhs: remote)
        XCTAssertEqual(merged.deviceName, "iPhone2")
        XCTAssertEqual(merged.deviceNameTimestamp, current)
        
        XCTAssertEqual(merged.phoneNumber, "7890")
        XCTAssertEqual(merged.phoneNumberTimestamp, past5SecondsAgo)
        
        XCTAssertEqual(merged.email, "1@gmail.com")
        XCTAssertEqual(merged.emailTimestamp, past15SecondsAgo)
        
        XCTAssertEqual(merged.authProvider, "google")
        XCTAssertEqual(merged.authProviderTimestamp, past15SecondsAgo)
    }
    
    func testMergeTwoDifferentMetadata() throws {
        let past5SecondsAgo = Date() - 5
        let past15SecondsAgo = Date() - 15
        let current = Date()

        let local = WalletMetaData(
            ethPublic: "123",
            deviceName: "iPhone1",
            deviceNameTimestamp: past5SecondsAgo,
            email: "1@gmail.com",
            emailTimestamp: past15SecondsAgo,
            authProvider: "google",
            authProviderTimestamp: past15SecondsAgo,
            phoneNumber: "12345",
            phoneNumberTimestamp: past15SecondsAgo,
            striga: .init(userIdTimestamp: past15SecondsAgo)
        )

        let remote = WalletMetaData(
            ethPublic: "456",
            deviceName: "iPhone2",
            deviceNameTimestamp: current,
            email: "1@gmail.com",
            emailTimestamp: past15SecondsAgo,
            authProvider: "google",
            authProviderTimestamp: past15SecondsAgo,
            phoneNumber: "12345",
            phoneNumberTimestamp: past15SecondsAgo,
            striga: .init(userIdTimestamp: past15SecondsAgo)
        )

        
        XCTAssertThrowsError(try WalletMetaData.merge(lhs: local, rhs: remote))
    }
}
