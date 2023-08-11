import BankTransfer
import Foundation
import Onboarding

extension WalletMetadataServiceImpl: StrigaMetadataProvider {
    public func getStrigaMetadata() async -> StrigaMetadata? {
        guard let metadata = metadata.value else {
            return nil
        }
        return .init(
            userId: metadata.striga.userId,
            email: metadata.email,
            phoneNumber: metadata.phoneNumber
        )
    }

    public func updateMetadata(withUserId userId: String) async {
        guard var newData = metadata.value else {
            return
        }
        newData.striga.userId = userId

        await update(newData)
    }
}
