import Foundation
import PnLService
import Repository

class PnLProvider: Provider {
    // MARK: - Dependencies

    let service: any PnLService

    // MARK: - Initializer

    init(service: any PnLService) {
        self.service = service
    }

    func fetch() async throws -> PnLModel? {
        try await service.getPNL()
    }
}

class PnLRepository: Repository<PnLProvider> {
//    weak var timer: Timer?

    override init(initialData: ItemType?, provider: PnLProvider) {
        super.init(initialData: initialData, provider: provider)
//        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
//            guard let self else { return }
//            Task { await self.refresh() }
//        }

        // wtf timer doesn't fire???

        scheduleRun()
    }

    // MARK: - Scheduler

    private func scheduleRun() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
            guard let self else { return }
            Task { await self.refresh() }
            self.scheduleRun()
        }
    }
}

class AccountPnLRepository: PnLRepository {}
