import Foundation

public struct StatsInfo: Codable {
    public enum OperationType: String, Codable {
        case topUp = "TopUp"
        case transfer = "Transfer"
        case swap = "Swap"
        case other = "Other"
        case sendViaLink = "SendViaLink"
    }
    
    public enum DeviceType: String, Codable {
        case web = "Web"
        case android = "Android"
        case iOS = "Ios"
    }

    public enum Environment: String, Codable {
        case dev
        case release
    }

    let operationType: OperationType
    let deviceType: DeviceType
    let currency: String?
    let build: String?
    let environment: Environment
    
    enum CodingKeys: String, CodingKey {
        case operationType = "operation_type"
        case deviceType = "device_type"
        case currency
        case build
        case environment
    }

    public init(operationType: StatsInfo.OperationType, deviceType: StatsInfo.DeviceType, currency: String?, build: String?, environment: Environment) {
        self.operationType = operationType
        self.deviceType = deviceType
        self.currency = currency
        self.build = build
        self.environment = environment
    }
}
