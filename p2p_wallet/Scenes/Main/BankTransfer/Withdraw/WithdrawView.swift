import SwiftUI
import Resolver
import BankTransfer
import Combine
import KeyAppUI

struct WithdrawView: View {
    @ObservedObject var viewModel: WithdrawViewModel
    @State private var focus: WithdrawViewField?

    var body: some View {
        ColoredBackground {
            VStack {
                ScrollView {
                    form
                        .animation(.spring(blendDuration: 0.01), value: viewModel.fieldsStatuses)
                }

                Spacer()

                NewTextButton(
                    title: viewModel.actionTitle.uppercaseFirst,
                    style: .primaryWhite,
                    expandable: true,
                    isEnabled: true,
                    isLoading: viewModel.isLoading,
                    trailing: viewModel.isDataValid ? .arrowForward : nil,
                    action: {
                        resignFirstResponder()
                        Task {
                            await viewModel.action()
                        }
                    }
                )
                .padding(.bottom, 20)
            }
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
                title: L10n.iban,
                status: viewModel.fieldsStatuses[.IBAN]
            ) {
                    StrigaRegistrationTextField<WithdrawViewField>(
                        field: .IBAN,
                        placeholder: "",
                        text: $viewModel.IBAN,
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
                        placeholder: "",
                        text: $viewModel.BIC,
                        focus: $focus,
                        onSubmit: { focus = nil },
                        submitLabel: .done
                    )
                }

            VStack(spacing: 4) {
                StrigaFormCell(
                    title: "Receiver",
                    status: .valid) {
                        StrigaRegistrationTextField<WithdrawViewField>(
                            field: .receiver,
                            placeholder: "",
                            text: $viewModel.receiver,
                            isEnabled: false,
                            focus: $focus,
                            onSubmit: { focus = nil },
                            submitLabel: .next
                        )
                    }
                Text("Your bank account name must match the name registered to your Key App account")
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
        }
    }
}

//struct WithdrawView_Previews: PreviewProvider {
//    static var previews: some View {
//        WithdrawView(viewModel: WithdrawViewModel(provider: Resolver.resolve(), withdrawalInfo: nil))
//    }
//}


enum WithdrawViewField: Int, Identifiable {
    var id: Int { rawValue }

    case IBAN
    case BIC
    case receiver
}

extension WithdrawView {
    // When screen disappear via some action, you should called this method twice for some reason: on action and on disappear function
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
