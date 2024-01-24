import Combine
import KeyAppBusiness
import Resolver
import Sell
import SwiftUI
import SwiftyUserDefaults

struct ActionsView: View {
    private let actionSubject = PassthroughSubject<ActionsViewActionType, Never>()
    var action: AnyPublisher<ActionsViewActionType, Never> { actionSubject.eraseToAnyPublisher() }
    private let cancelSubject = PassthroughSubject<Void, Never>()
    var cancel: AnyPublisher<Void, Never> { cancelSubject.eraseToAnyPublisher() }

    var body: some View {
        VStack(spacing: 8) {
            Color(.rain)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
            Text(L10n.addMoney)
                .foregroundColor(Color(.night))
                .font(uiFont: .font(of: .text1, weight: .bold))
                .padding(.top, 8)
            VStack(spacing: 8) {
                ForEach(ActionsViewActionType.allCases, id: \.title) { actionType in
                    ActionsCellView(
                        icon: actionType.icon,
                        title: actionType.title,
                        subtitle: actionType.subtitle
                    ) {
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
        .background(Color(.smoke))
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
