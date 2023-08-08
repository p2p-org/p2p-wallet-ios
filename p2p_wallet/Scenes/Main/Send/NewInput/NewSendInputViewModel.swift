import Combine
import Foundation
import KeyAppKitCore
import KeyAppUI
import Resolver

final class NSendInputViewModel: BaseViewModel, ObservableObject {
    // MARK: - Type

    enum Status {
        case initializing
        case initializingFailed
        case ready
    }

    // MARK: - Depedencies

    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Subview models

    let inputAmountViewModel: SendInputAmountViewModel

    // MARK: - Configuration

    private let isTokenChoiceEnabled: Bool
    private let preChosenAmount: Double?
    private let allowSwitchingMainAmountType: Bool

    // MARK: - Properties

    @Published var status: Status = .initializing
    @Published var sourceWallet: SolanaAccount

    @Published var feeTitle = L10n.fees("")
    @Published var isFeeLoading: Bool = true
    @Published var loadingState: LoadableState = .loaded

    @Published var actionButtonData = SliderActionButtonData.zero
    @Published var isSliderOn = false
    @Published var showFinished = false

    private var wasMaxWarningToastShown: Bool = false

    // MARK: - Actions

    let changeTokenPressed = PassthroughSubject<Void, Never>()
    let feeInfoPressed = PassthroughSubject<Void, Never>()
    let openFeeInfo = PassthroughSubject<Bool, Never>()
    let changeFeeToken = PassthroughSubject<SolanaAccount, Never>()
    let snackbar = PassthroughSubject<SnackBar, Never>()
    let transaction = PassthroughSubject<SendTransaction, Never>()
}
