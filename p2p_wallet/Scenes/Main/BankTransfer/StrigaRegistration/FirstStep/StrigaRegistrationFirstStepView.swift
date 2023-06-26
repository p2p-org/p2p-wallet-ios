import SwiftUI
import KeyAppUI
import CountriesAPI

fileprivate typealias TextField = StrigaRegistrationTextField
fileprivate typealias Cell = StrigaRegistrationCell
fileprivate typealias DetailedButton = StrigaRegistrationDetailedButton

struct StrigaRegistrationFirstStepView: View {
    @ObservedObject private var viewModel: StrigaRegistrationFirstStepViewModel

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
                            action: viewModel.actionPressed.send
                        )
                            .padding(.bottom, 20)
                    }
                        .padding(.horizontal, 16)
                }
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
                    TextField(placeholder: L10n.enter, text: $viewModel.email, isEnabled: false)
                }

                Cell(
                    title: L10n.phoneNumber,
                    status: viewModel.fieldsStatuses[.phoneNumber]
                ) {
                    StrigaRegistrationPhoneTextField(
                        text: $viewModel.phoneNumber,
                        phoneNumber: $viewModel.phoneNumberModel,
                        country: $viewModel.selectedPhoneCountryCode,
                        action: { [weak viewModel] in
                            guard let viewModel else { return }
                            viewModel.choosePhoneCountryCode.send(viewModel.selectedPhoneCountryCode)
                        }
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
                    TextField(placeholder: L10n.enter, text: $viewModel.firstName)
                }

                Cell(
                    title: L10n.surname,
                    status: viewModel.fieldsStatuses[.surname]
                ) {
                    TextField(placeholder: L10n.enter, text: $viewModel.surname)
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
                    StrigaRegistrationDateTextField(text: $viewModel.dateOfBirth)
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
                        }
                    )
                }
            }
        }
    }
}

struct StrigaRegistrationFirstStepView_Previews: PreviewProvider {
    static var previews: some View {
        StrigaRegistrationFirstStepView(
            viewModel: StrigaRegistrationFirstStepViewModel(country: Country(name: "France", code: "FR", dialCode: "", emoji: "🇫🇷", alpha3Code: "FRA"))
        )
    }
}

struct StrigaRegistrationSectionView: View {
    var title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text(title.uppercased())
                .apply(style: .caps)
                .foregroundColor(Color(Asset.Colors.night.color))
        }
            .frame(minHeight: 33)
    }
}
