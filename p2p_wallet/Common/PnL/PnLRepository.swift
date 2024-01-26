import Foundation
import PnLService
import Repository

class PnLProvider: Provider {
    // MARK: - Dependencies

    let service: PnLService

    // MARK: - Initializer

    init(service: PnLService) {
        self.service = service
    }

    func fetch() async throws -> String? {
        try await service.getPNL()
    }
}

class PnLRepository: Repository<PnLProvider> {
    override init(initialData: ItemType?, provider: PnLProvider) {
        super.init(initialData: initialData, provider: provider)
    }
}
