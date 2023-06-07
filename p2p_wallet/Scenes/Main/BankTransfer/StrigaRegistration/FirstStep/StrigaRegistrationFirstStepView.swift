import SwiftUI
import KeyAppUI
import CountriesAPI

fileprivate typealias TextField = StrigaRegistrationTextField
fileprivate typealias InfoView = StrigaRegistrationInfoView
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
            content
        }
    }
    
    var content: some View {
        List {
            InfoView(appearance: .credentials)
                .listRowBackground(Color(Asset.Colors.smoke.color))
                .listRowInsets(EdgeInsets.infoInset)
            
            contactsSection
            credentialsSection
            dateOfBirthSection

            NewTextButton(
                title: viewModel.actionTitle.uppercaseFirst,
                style: .primaryWhite,
                isEnabled: viewModel.isDataValid,
                trailing: viewModel.isDataValid ? .arrowForward : nil,
                action: viewModel.actionPressed.send
            )
            .listRowInsets(EdgeInsets.infoInset)
            .listRowBackground(Color(Asset.Colors.smoke.color))
        }
        .listStyle(.insetGrouped)
        .modifier(ListBackgroundModifier(separatorColor: .clear))
        .background(
            Color(asset: Asset.Colors.smoke).ignoresSafeArea()
        )
    }

    var contactsSection: some View {
        Section(header: section(header: L10n.contacts)) {
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
                StrigaRegistrationPhoneTextField(text: $viewModel.phoneNumber, phoneNumber: $viewModel.phoneNumberModel)
            }
        }
        .styled()
    }

    var credentialsSection: some View {
        Section(header: section(header: L10n.credentials)) {
            Cell(
                title: L10n.firstName,
                status: viewModel.fieldsStatuses[.firstName]
            ) {
                TextField(placeholder: L10n.enter, text: $viewModel.firstName, maxSymbolsLimit: 40)
            }

            Cell(
                title: L10n.surname,
                status: viewModel.fieldsStatuses[.surname]
            ) {
                TextField(placeholder: L10n.enter, text: $viewModel.surname, maxSymbolsLimit: 40)
            }
        }
        .styled()
    }

    var dateOfBirthSection: some View {
        Section(header: section(header: L10n.dateOfBirth)) {
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
                    action: { }
                )
            }
            .onTapGesture {
                viewModel.chooseCountry.send(viewModel.selectedCountryOfBirth)
            }
        }
        .styled()
    }
}

private extension Section where Parent: View, Content: View, Footer == EmptyView {
    func styled() -> some View {
        return self.listRowBackground(Color(Asset.Colors.smoke.color))
            .listRowInsets(EdgeInsets.rowInset)
            .modifier(ListBackgroundModifier(separatorColor: .clear))
    }
}

private extension StrigaRegistrationFirstStepView {
    func section(header: String) -> some View {
        Text(header).foregroundColor(Color(asset: Asset.Colors.night)).padding(.leading, 8)
    }
}

private extension EdgeInsets {
    static let rowInset = EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0)
    static let infoInset = EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)
}

struct StrigaRegistrationFirstStepView_Previews: PreviewProvider {
    static var previews: some View {
        StrigaRegistrationFirstStepView(
            viewModel: StrigaRegistrationFirstStepViewModel(country: Country(name: "France", code: "FR", dialCode: "", emoji: "🇫🇷", alpha3Code: "FRA"))
        )
    }
}
