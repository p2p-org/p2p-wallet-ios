import SwiftUI
import KeyAppUI

fileprivate typealias TextField = StrigaRegistrationTextField
fileprivate typealias Cell = StrigaFormCell
fileprivate typealias DetailedButton = StrigaRegistrationDetailedButton

struct StrigaRegistrationSecondStepView: View {
    @ObservedObject private var viewModel: StrigaRegistrationSecondStepViewModel
    @State private var focus: StrigaRegistrationField?

    init(viewModel: StrigaRegistrationSecondStepViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ColoredBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    BaseInformerView(data: StrigaRegistrationInfoViewModel.credentials)
                        .padding(.top, 22)
                    sourceOfFundsSection
                    ListSpacerCellView(height: 10, backgroundColor: .clear)
                    VStack(spacing: 32) {
                        addressSection
                        BaseInformerView(data: StrigaRegistrationInfoViewModel.confirm)
                    }
                    ListSpacerCellView(height: 12, backgroundColor: .clear)
                    NewTextButton(
                        title: viewModel.actionTitle.uppercaseFirst,
                        style: .primaryWhite,
                        expandable: true,
                        isEnabled: viewModel.isDataValid,
                        isLoading: viewModel.isLoading,
                        trailing: viewModel.isDataValid ? .arrowForward : nil,
                        action: viewModel.actionPressed.send
                    )
                    .padding(.bottom, 14)
                }
                    .padding(.horizontal, 16)
            }
        }
    }

    var sourceOfFundsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StrigaRegistrationSectionView(title: L10n.sourceOfFunds)
                .padding(.horizontal, 9)
            VStack(spacing: 23) {
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
        }
    }

    var addressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StrigaRegistrationSectionView(title: L10n.currentAddress)
                .padding(.horizontal, 9)
            VStack(spacing: 23) {
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
                    TextField(
                        field: .city,
                        placeholder: L10n.fullCityName,
                        text: $viewModel.city,
                        focus: $focus,
                        onSubmit: { focus = .addressLine },
                        submitLabel: .next
                    )
                }

                Cell(
                    title: L10n.addressLine,
                    status: viewModel.fieldsStatuses[.addressLine]
                ) {
                    TextField(
                        field: .addressLine,
                        placeholder: L10n.yourStreetAndFlatNumber,
                        text: $viewModel.addressLine,
                        focus: $focus,
                        onSubmit: { focus = .postalCode },
                        submitLabel: .next
                    )
                }

                Cell(
                    title: L10n.postalCode,
                    status: viewModel.fieldsStatuses[.postalCode]
                ) {
                    TextField(
                        field: .postalCode,
                        placeholder: L10n.yourPostalCode,
                        text: $viewModel.postalCode,
                        focus: $focus,
                        onSubmit: { focus = .stateRegion },
                        submitLabel: .next
                    )
                }

                Cell(
                    title: L10n.stateOrRegion,
                    status: viewModel.fieldsStatuses[.stateRegion]
                ) {
                    TextField(
                        field: .stateRegion,
                        placeholder: L10n.recommended,
                        text: $viewModel.stateRegion,
                        focus: $focus,
                        onSubmit: { focus = nil },
                        submitLabel: .done
                    )
                }
            }
        }
    }
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
