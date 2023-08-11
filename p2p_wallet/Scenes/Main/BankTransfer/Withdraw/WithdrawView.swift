import BankTransfer
import Combine
import KeyAppUI
import Resolver
import SwiftUI

struct WithdrawView: View {
    @ObservedObject var viewModel: WithdrawViewModel
    @State private var focus: WithdrawViewField?

    var body: some View {
        ColoredBackground {
            VStack {
                ScrollView {
                    form
                        .padding(.top, 16)
                        .animation(.spring(blendDuration: 0.01), value: viewModel.fieldsStatuses)
                }
            }
            .safeAreaInset(edge: .bottom, content: {
                NewTextButton(
                    title: viewModel.actionTitle.uppercaseFirst,
                    style: .primaryWhite,
                    expandable: true,
                    isEnabled: viewModel.isDataValid || !viewModel.actionHasBeenTapped,
                    isLoading: viewModel.isLoading,
                    trailing: viewModel.isDataValid ? .arrowForward : nil,
                    action: {
                        resignFirstResponder()
                        Task {
                            await viewModel.action()
                        }
                    }
                )
                .padding(.top, 12)
                .padding(.bottom, 36)
                .background(Color(Asset.Colors.smoke.color).edgesIgnoringSafeArea(.bottom))
            })
            .padding(.horizontal, 16)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(L10n.withdraw)
                    .fontWeight(.semibold)
            }
        }
        .onDisappear {
            resignFirstResponder()
        }
    }

    var form: some View {
        VStack(spacing: 12) {
            StrigaFormCell(
                title: L10n.yourIBAN,
                status: viewModel.fieldsStatuses[.IBAN]
            ) {
                StrigaRegistrationTextField<WithdrawViewField>(
                    field: .IBAN,
                    fontStyle: .text3,
                    placeholder: "",
                    text: $viewModel.IBAN,
                    showClearButton: true,
                    focus: $focus,
                    onSubmit: { focus = .BIC },
                    submitLabel: .next
                )
            }

            StrigaFormCell(
                title: L10n.bic,
                status: viewModel.fieldsStatuses[.BIC]
            ) {
                StrigaRegistrationTextField<WithdrawViewField>(
                    field: .BIC,
                    fontStyle: .text3,
                    placeholder: "",
                    text: $viewModel.BIC,
                    showClearButton: true,
                    focus: $focus,
                    onSubmit: { focus = nil },
                    submitLabel: .done
                )
            }

            VStack(spacing: 4) {
                StrigaFormCell(
                    title: L10n.receiver,
                    status: .valid
                ) {
                    StrigaRegistrationTextField<WithdrawViewField>(
                        field: .receiver,
                        fontStyle: .text3,
                        placeholder: "",
                        text: $viewModel.receiver,
                        isEnabled: false,
                        focus: $focus,
                        onSubmit: { focus = nil },
                        submitLabel: .next
                    )
                }
                Text(L10n.yourBankAccountNameMustMatchTheNameRegisteredToYourKeyAppAccount)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
        }
    }
}

// struct WithdrawView_Previews: PreviewProvider {
//    static var previews: some View {
//        WithdrawView(viewModel: WithdrawViewModel(provider: Resolver.resolve(), withdrawalInfo: nil))
//    }
// }

enum WithdrawViewField: Int, Identifiable {
    var id: Int { rawValue }

    case IBAN
    case BIC
    case receiver
}

extension WithdrawView {
    // When screen disappear via some action, you should called this method twice for some reason: on action and on
    // disappear function
    // Seems like a UI bug of iOS https://stackoverflow.com/a/74124962
    private func resignFirstResponder() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
