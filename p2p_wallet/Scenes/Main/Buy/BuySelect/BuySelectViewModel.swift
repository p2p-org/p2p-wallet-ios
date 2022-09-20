import Combine
import SolanaSwift

class BuySelectViewModel<Model: Hashable>: ObservableObject {
    @Published var selectedModel: Model?

    var coordinatorIO = CoordinatorIO()

    var items: [Model] = []

    init(items: [Model], selectedModel: Model? = nil) {
        self.items = items
        self.selectedModel = selectedModel
    }

    func didTapOn(model: Model) {
        coordinatorIO.didSelectModel.send(model)
    }

    struct CoordinatorIO {
        var didSelectModel = PassthroughSubject<Model, Never>()
        var didDissmiss = PassthroughSubject<Void, Never>()
    }
}
