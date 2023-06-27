//
//  AppInfo.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/05/2023.
//

import Foundation

enum AppInfo {
    static var appVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "" }
    static var appVersionDetail: String {
        "\(appVersion)\(Environment.current != .release ? ("(" + Bundle.main.buildVersionNumber + ")" + " " + Environment.current.description) : "")"
    }
}

// MARK: - Environment Description

private extension Environment {
    var description: String {
        switch self {
        case .debug:
            return "Debug"
        case .test:
            return "Test"
        case .release:
            return "Release"
        }
    }
}
