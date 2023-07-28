import Combine
import KeyAppBusiness
import KeyAppUI
import Resolver
import Sell
import SwiftUI
import SwiftyUserDefaults

struct ActionsView: View {
    @Injected private var sellDataService: any SellDataService
    @Injected private var walletsRepository: SolanaAccountsService

    private let actionSubject = PassthroughSubject<ActionsViewActionType, Never>()
    var action: AnyPublisher<ActionsViewActionType, Never> { actionSubject.eraseToAnyPublisher() }
    private let cancelSubject = PassthroughSubject<Void, Never>()
    var cancel: AnyPublisher<Void, Never> { cancelSubject.eraseToAnyPublisher() }
    var isSellAvailable: Bool {
        available(.sellScenarioEnabled) &&
            sellDataService.isAvailable &&
            !walletsRepository.getWallets().isTotalAmountEmpty
    }

    var body: some View {
        VStack(spacing: 8) {
            Color(Asset.Colors.rain.color)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
            Text(L10n.addMoney)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .text1, weight: .bold))
                .padding(.top, 8)
            VStack(spacing: 8) {
                ForEach(ActionsViewActionType.allCases, id: \.title) { actionType in
                    ActionsCellView(icon: actionType.icon, title: actionType.title, subtitle: actionType.subtitle) {
                        actionSubject.send(actionType)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.top, 12)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .padding(.top, 6)
        .background(Color(Asset.Colors.smoke.color))
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Action

extension ActionsView {
    enum Action {
        case buy
        case receive
        case swap
        case send
        case cashOut
    }
}

// MARK: - View Height

extension ActionsView {
    var viewHeight: CGFloat {
        (UIScreen.main.bounds.width - 16 * 3)
            + (UIApplication.shared.kWindow?.safeAreaInsets.bottom ?? 0)
    }
}
