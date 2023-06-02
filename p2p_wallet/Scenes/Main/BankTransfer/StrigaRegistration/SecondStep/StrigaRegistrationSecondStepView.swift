import SwiftUI
import KeyAppUI

fileprivate typealias TextField = StrigaRegistrationTextField
fileprivate typealias InfoView = StrigaRegistrationInfoView
fileprivate typealias Cell = StrigaRegistrationCell
fileprivate typealias DetailedButton = StrigaRegistrationDetailedButton

struct StrigaRegistrationSecondStepView: View {
    @ObservedObject private var viewModel: StrigaRegistrationSecondStepViewModel

    init(viewModel: StrigaRegistrationSecondStepViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            InfoView(appearance: .credentials)
                .listRowBackground(Color(Asset.Colors.smoke.color))
                .listRowInsets(EdgeInsets.infoInset)

            sourceOfFundsSection
            addressSection

            InfoView(appearance: .confirm)
                .listRowBackground(Color(Asset.Colors.smoke.color))
                .listRowInsets(EdgeInsets.infoInset)

            NewTextButton(
                title: viewModel.actionTitle.uppercaseFirst,
                style: .primaryWhite,
                isEnabled: viewModel.isDataValid,
                isLoading: viewModel.isLoading,
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

    var sourceOfFundsSection: some View {
        Section(header: section(header: L10n.sourceOfFunds)) {
            Cell(
                title: L10n.occupationIndustry,
                status: viewModel.fieldsStatuses[.occupationIndustry]
            ) {
                DetailedButton(value: $viewModel.occupationIndustry, action: {
                    viewModel.chooseIndustry.send(viewModel.selectedIndustry)
                })
            }

            Cell(
                title: L10n.sourceOfFunds,
                status: viewModel.fieldsStatuses[.sourceOfFunds]
            ) {
                DetailedButton(value: $viewModel.sourceOfFunds, action: {
                    viewModel.chooseSourceOfFunds.send(viewModel.selectedSourceOfFunds)
                })
            }
        }
        .styled()
    }

    var addressSection: some View {
        Section(header: section(header: L10n.currentAddress)) {
            Cell(
                title: L10n.country,
                status: viewModel.fieldsStatuses[.country]
            ) {
                DetailedButton(value: $viewModel.country, action: {
                    viewModel.chooseCountry.send(viewModel.selectedCountry)
                })
            }

            Cell(
                title: L10n.city,
                status: viewModel.fieldsStatuses[.city]
            ) {
                TextField(placeholder: L10n.fullCityName, text: $viewModel.city, maxSymbolsLimit: 40)
            }

            Cell(
                title: L10n.addressLine,
                status: viewModel.fieldsStatuses[.addressLine]
            ) {
                TextField(placeholder: L10n.yourStreetAndFlatNumber, text: $viewModel.addressLine, maxSymbolsLimit: 160)
            }

            Cell(
                title: L10n.postalCode,
                status: viewModel.fieldsStatuses[.postalCode]
            ) {
                TextField(placeholder: L10n.recommended, text: $viewModel.postalCode, maxSymbolsLimit: 20)
            }

            Cell(
                title: L10n.stateOrRegion,
                status: viewModel.fieldsStatuses[.stateRegion]
            ) {
                TextField(placeholder: L10n.recommended, text: $viewModel.stateRegion, maxSymbolsLimit: 20)
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

private extension StrigaRegistrationSecondStepView {
    func section(header: String) -> some View {
        Text(header).foregroundColor(Color(asset: Asset.Colors.night)).padding(.leading, 8)
    }
}

private extension EdgeInsets {
    static let rowInset = EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0)
    static let infoInset = EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)
}

struct StrigaRegistrationSecondStepView_Previews: PreviewProvider {
    static var previews: some View {
        StrigaRegistrationSecondStepView(
            viewModel: StrigaRegistrationSecondStepViewModel(
                data: .init(
                    firstName: "test",
                    lastName: "test",
                    email: "test@test.com",
                    mobile: .init(countryCode: "", number: ""),
                    KYC: .init(
                        status: .notStarted,
                        mobileVerified: false
                    )
                )
            )
        )
    }
}
