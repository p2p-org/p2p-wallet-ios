import Combine
import KeyAppBusiness
import KeyAppUI
import Resolver
import Sell
import SwiftUI
import SwiftyUserDefaults

struct ActionsView: View {
<<<<<<< HEAD
    @SwiftUI.Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ActionsViewModel

    let columns = [
        GridItem(.adaptive(minimum: 154, maximum: .infinity)),
    ]

    var body: some View {
        VStack(spacing: 22) {
            Color(Asset.Colors.rain.color)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
                .padding(.top, 6)
            Text(L10n.actions)
                .foregroundColor(Color(Asset.Colors.night.color))
                .fontWeight(.bold)
                .apply(style: .title3)
                .padding(.top, 2)
            VStack(spacing: 8) {
                if viewModel.horizontal.count > 0 {
                    ForEach(viewModel.horizontal) { item in
                        horizontalActionView(
                            image: item.image,
                            title: item.title,
                            subtitle: item.subtitle,
                            action: item.action
                        )
                    }
                }
                LazyVGrid(columns: columns) {
                    ForEach(viewModel.vertical) { item in
                        actionView(
                            image: item.image,
                            title: item.title,
                            subtitle: item.subtitle,
                            action: item.action
                        )
                    }
                }
            }
            .padding(.top, 7)

            Button(
                action: {
                    presentationMode.wrappedValue.dismiss()
                },
                label: {
                    Text(L10n.cancel)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text1, weight: .bold))
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.rain.color))
                        .cornerRadius(12)
                }
            )
            .padding(.top, 21)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .previewLayout(.sizeThatFits)
    }

    func actionView(
        image: UIImage,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            action: action,
            label: {
                ZStack(alignment: .leading) {
                    Color(Asset.Colors.snow.color)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(167/148, contentMode: .fit)
                        .shadow(
                            color: Color(UIColor(red: 0.043, green: 0.122, blue: 0.208, alpha: 0.1)),
                            radius: 128,
                            x: 9,
                            y: 22
                        )
                    VStack(alignment: .leading, spacing: 12) {
                        Image(uiImage: image)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(title)
                                .foregroundColor(Color(Asset.Colors.night.color))
                                .font(uiFont: .font(of: .text1, weight: .bold))
                            Text(subtitle)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .font(uiFont: .font(of: .label1, weight: .regular))
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        )
    }

    func horizontalActionView(
        image: UIImage,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            action: action,
            label: {
                ZStack(alignment: .leading) {
                    Color(Asset.Colors.snow.color)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
                        )
                        .shadow(
                            color: Color(UIColor(red: 0.043, green: 0.122, blue: 0.208, alpha: 0.1)),
                            radius: 128,
                            x: 9,
                            y: 22
                        )
                    VStack(alignment: .leading, spacing: 12) {
                        Image(uiImage: image)
                            .padding(EdgeInsets(top: 30, leading: 20, bottom: 0, trailing: 0))
                        VStack(alignment: .leading, spacing: 8) {
                            Text(title)
                                .foregroundColor(Color(Asset.Colors.night.color))
                                .font(uiFont: .font(of: .text1, weight: .bold))
                            Text(subtitle)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .font(uiFont: .font(of: .label1, weight: .regular))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
        )
    }
=======
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
>>>>>>> develop
}

// MARK: - Action

extension ActionsView {
    enum Action {
        case buy
        case topUp
        case receive
        case swap
        case send
        case cashOut
    }
}
<<<<<<< HEAD
=======

// MARK: - View Height

extension ActionsView {
    var viewHeight: CGFloat {
        (UIScreen.main.bounds.width - 16 * 3)
            + (UIApplication.shared.kWindow?.safeAreaInsets.bottom ?? 0)
    }
}
>>>>>>> develop
