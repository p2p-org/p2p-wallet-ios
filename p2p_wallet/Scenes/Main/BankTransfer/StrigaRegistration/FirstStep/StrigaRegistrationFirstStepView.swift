import SwiftUI
import KeyAppUI
import CountriesAPI

fileprivate typealias TextField = StrigaRegistrationTextField
fileprivate typealias Cell = StrigaRegistrationCell
fileprivate typealias DetailedButton = StrigaRegistrationDetailedButton

struct StrigaRegistrationFirstStepView: View {

    @ObservedObject private var viewModel: StrigaRegistrationFirstStepViewModel

    @State private var focus: StrigaRegistrationField?

    init(viewModel: StrigaRegistrationFirstStepViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        if viewModel.isLoading {
            ProgressView()
        } else {
            ColoredBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        BaseInformerView(data: StrigaRegistrationInfoViewModel.credentials)
                            .padding(.top, 22)

                        contactsSection
                        ListSpacerCellView(height: 10, backgroundColor: .clear)
                        credentialsSection
                        ListSpacerCellView(height: 10, backgroundColor: .clear)
                        dateOfBirthSection
                        ListSpacerCellView(height: 28, backgroundColor: .clear)

                        NewTextButton(
                            title: viewModel.actionTitle.uppercaseFirst,
                            style: .primaryWhite,
                            expandable: true,
                            isEnabled: viewModel.isDataValid,
                            trailing: viewModel.isDataValid ? .arrowForward : nil,
                            action: {
                                resignFirstResponder()
                                viewModel.actionPressed.send()
                            }
                        )
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .onDisappear {
                resignFirstResponder()
            }
        }
    }

    var contactsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StrigaRegistrationSectionView(title: L10n.contacts)
                .padding(.horizontal, 9)
            VStack(spacing: 23) {
                Cell(
                    title: L10n.email,
                    status: viewModel.fieldsStatuses[.email]
                ) {
                    TextField(
                        field: .email,
                        placeholder: L10n.enter,
                        text: $viewModel.email,
                        isEnabled: false,
                        focus: $focus,
                        onSubmit: { },
                        submitLabel: .next
                    )
                }

                Cell(
                    title: L10n.phoneNumber,
                    status: viewModel.fieldsStatuses[.phoneNumber]
                ) {
                    StrigaRegistrationPhoneTextField(
                        text: $viewModel.phoneNumber,
                        phoneNumber: $viewModel.phoneNumberModel,
                        country: $viewModel.selectedPhoneCountryCode,
                        countryTapped: { [weak viewModel] in
                            guard let viewModel else { return }
                            viewModel.choosePhoneCountryCode.send(viewModel.selectedPhoneCountryCode)
                            resignFirstResponder()
                        },
                        focus: $focus
                    )
                }
            }
        }
    }

    var credentialsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StrigaRegistrationSectionView(title: L10n.credentials)
                .padding(.horizontal, 9)
            VStack(spacing: 23) {
                Cell(
                    title: L10n.firstName,
                    status: viewModel.fieldsStatuses[.firstName]
                ) {
                    TextField(
                        field: .firstName,
                        placeholder: L10n.enter,
                        text: $viewModel.firstName,
                        focus: $focus,
                        onSubmit: { focus = .surname },
                        submitLabel: .next
                    )
                }

                Cell(
                    title: L10n.surname,
                    status: viewModel.fieldsStatuses[.surname]
                ) {
                    TextField(
                        field: .surname,
                        placeholder: L10n.enter,
                        text: $viewModel.surname,
                        focus: $focus,
                        onSubmit: { focus = .dateOfBirth },
                        submitLabel: .next
                    )
                }
            }
        }
    }

    var dateOfBirthSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StrigaRegistrationSectionView(title: L10n.dateOfBirth)
                .padding(.horizontal, 9)
            VStack(spacing: 23) {
                Cell(
                    title: L10n.dateOfBirth,
                    status: viewModel.fieldsStatuses[.dateOfBirth]
                ) {
                    StrigaRegistrationDateTextField(
                        text: $viewModel.dateOfBirth,
                        focus: $focus
                    )
                }

                Cell(
                    title: L10n.countryOfBirth,
                    status: viewModel.fieldsStatuses[.countryOfBirth]
                ) {
                    DetailedButton(
                        value: $viewModel.countryOfBirth,
                        action: { [weak viewModel] in
                            guard let viewModel else { return }
                            viewModel.chooseCountry.send(viewModel.selectedCountryOfBirth)
                            resignFirstResponder()
                        }
                    )
                }
            }
        }
    }

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

struct StrigaRegistrationFirstStepView_Previews: PreviewProvider {
    static var previews: some View {
        StrigaRegistrationFirstStepView(viewModel: StrigaRegistrationFirstStepViewModel())
    }
}
