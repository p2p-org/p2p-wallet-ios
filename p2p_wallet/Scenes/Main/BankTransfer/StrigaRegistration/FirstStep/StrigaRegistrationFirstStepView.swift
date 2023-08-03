import CountriesAPI
import KeyAppUI
import SwiftUI

private typealias TextField = StrigaRegistrationTextField
private typealias Cell = StrigaFormCell
private typealias DetailedButton = StrigaRegistrationDetailedButton

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

                        fields
                        ListSpacerCellView(height: 10, backgroundColor: .clear)

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

    var fields: some View {
        VStack(alignment: .leading, spacing: 14) {
            StrigaRegistrationSectionView(title: L10n.personalInformation)
                .padding(.horizontal, 9)
            VStack(spacing: 23) {
                Cell(
                    title: L10n.fullLegalFirstAndMiddleNames,
                    status: viewModel.fieldsStatuses[.firstName],
                    hint: L10n.spellYourNameExactlyAsItSShownOnYourPassportOrIDCard
                ) {
                    TextField(
                        field: .firstName,
                        placeholder: L10n.firstName,
                        text: $viewModel.firstName,
                        focus: $focus,
                        onSubmit: { focus = .surname },
                        submitLabel: .next
                    )
                }

                Cell(
                    title: L10n.fullLegalLastNameS,
                    status: viewModel.fieldsStatuses[.surname],
                    hint: L10n.spellYourNameExactlyAsItSShownOnYourPassportOrIDCard
                ) {
                    TextField(
                        field: .surname,
                        placeholder: L10n.lastName,
                        text: $viewModel.surname,
                        focus: $focus,
                        onSubmit: { focus = .phoneNumber },
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

struct StrigaRegistrationFirstStepView_Previews: PreviewProvider {
    static var previews: some View {
        StrigaRegistrationFirstStepView(viewModel: StrigaRegistrationFirstStepViewModel())
    }
}
