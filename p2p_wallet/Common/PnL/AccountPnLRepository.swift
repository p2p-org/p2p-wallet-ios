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
    weak var timer: Timer?

    override init(initialData: ItemType?, provider: PnLProvider) {
        super.init(initialData: initialData, provider: provider)
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.refresh() }
        }
    }

    deinit {
        timer?.invalidate()
    }
}

class AccountPnLRepository: PnLRepository {}
