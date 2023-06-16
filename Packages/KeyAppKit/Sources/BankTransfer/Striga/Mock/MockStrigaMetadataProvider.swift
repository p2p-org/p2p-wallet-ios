import Foundation

public class MockStrigaMetadataProvider: StrigaMetadataProvider {
    private var metadata: StrigaMetadata
    
    public init(useCase: MockStrigaUseCase, mockUserId: String) {
        let userId: String?
        switch useCase {
        case .unregisteredUser:
            userId = nil
        case .registeredUserWithUnverifiedOTP:
            userId = mockUserId
        case .registeredUserWithoutKYC:
            userId = mockUserId
        case .registeredAndVerifiedUser:
            userId = mockUserId
        }
        self.metadata = .init(userId: userId, email: "elon.musk@gmail.com", phoneNumber: "+84773497461")
    }
    
    public func getStrigaMetadata() async -> StrigaMetadata? {
        metadata
    }
    
    public func updateMetadata(withUserId userId: String) async throws {
        metadata = .init(userId: userId, email: metadata.email, phoneNumber: metadata.phoneNumber)
    }
}
