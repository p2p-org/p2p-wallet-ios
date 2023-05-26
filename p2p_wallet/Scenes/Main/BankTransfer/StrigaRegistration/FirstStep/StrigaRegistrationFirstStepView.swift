import SwiftUI
import KeyAppUI
import CountriesAPI

fileprivate typealias TextField = StrigaRegistrationTextField
fileprivate typealias InfoView = StrigaRegistrationInformerView

struct StrigaRegistrationFirstStepView: View {
    @ObservedObject private var viewModel: StrigaRegistrationFirstStepViewModel

    init(viewModel: StrigaRegistrationFirstStepViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            List {
                InfoView()
                    .listRowBackground(Color(Asset.Colors.smoke.color))
                    .listRowInsets(EdgeInsets.infoInset)

                contactsSection
                credentialsSection
                dateOfBirthSection
            }
            .listStyle(.insetGrouped)
            .modifier(ListBackgroundModifier(separatorColor: .clear))
            .background(Color(asset: Asset.Colors.smoke))

            NewTextButton(
                title: viewModel.actionTitle.uppercaseFirst,
                style: .primaryWhite,
                isEnabled: viewModel.isDataValid,
                trailing: viewModel.isDataValid ? .arrowForward : nil,
                action: viewModel.actionPressed.send
            )
            .padding(.all, 16)
        }.background(
            Color(asset: Asset.Colors.smoke).ignoresSafeArea()
        ).navigationBarItems(leading: Button(action: viewModel.back.send, label: {
            Image(uiImage: .backArrow)
                .renderingMode(.template)
                .foregroundColor(Color(asset: Asset.Colors.night))
        }))
    }

    var contactsSection: some View {
        Section(header: section(header: L10n.contacts)) {
            TextField(
                title: L10n.email,
                placeholder: L10n.enter,
                text: $viewModel.email,
                status: viewModel.fieldsStatuses[.email],
                isEnabled: false
            )

            TextField(
                title: L10n.phoneNumber,
                placeholder: L10n.enter,
                text: $viewModel.phoneNumber,
                status: viewModel.fieldsStatuses[.phoneNumber],
                maxSymbolsLimit: 12
            )
        }
        .styled()
    }

    var credentialsSection: some View {
        Section(header: section(header: L10n.credentials)) {
            TextField(
                title: L10n.firstName,
                placeholder: L10n.enter,
                text: $viewModel.firstName,
                status: viewModel.fieldsStatuses[.firstName],
                maxSymbolsLimit: 40
            )

            TextField(
                title: L10n.surname,
                placeholder: L10n.enter,
                text: $viewModel.surname,
                status: viewModel.fieldsStatuses[.surname],
                maxSymbolsLimit: 40
            )
        }
        .styled()
    }

    var dateOfBirthSection: some View {
        Section(header: section(header: L10n.dateOfBirth)) {
            StrigaRegistrationDateTextField(
                text: $viewModel.dateOfBirth,
                status: viewModel.fieldsStatuses[.dateOfBirth]
            )

            TextField(
                title: L10n.countryOfBirth,
                placeholder: L10n.selectFromList,
                text: $viewModel.countryOfBirth,
                status: viewModel.fieldsStatuses[.countryOfBirth],
                isDetailed: true
            )
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
            viewModel: StrigaRegistrationFirstStepViewModel(country: Country(name: "France", code: "FR", dialCode: "", emoji: "🇫🇷"))
        )
    }
}
