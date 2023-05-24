import BankTransfer
import CountriesAPI
import SwiftUI
import Foundation
import Resolver
import KeyAppUI

final class BankTransferInfoViewModel: BaseViewModel, ObservableObject {

    // MARK: - Dependencies

    @Injected private var bankTransferService: BankTransferService
    @Injected private var countriesService: CountriesAPI

    // MARK: -

    @Published var items: [any Renderable] = []

    // MARK: -

    private var currentCountry: Country? {
        didSet {
            self.items = self.makeItems()
        }
    }

    override init() {
        super.init()

        bind()
    }

    func bind() {
        Task {
            do {
                self.currentCountry = try await countriesService.currentCountryName()
            } catch {
//                DefaultLogManager.shared.log(
//                    event: "BankTransferInfoViewModel",
//                    data: "CountriesService:currentCountryName",
//                    logLevel: .error
//                )
            }
        }

        bankTransferService.userData
            .map { _ in self.makeItems() }
            .assignWeak(to: \.items, on: self)
            .store(in: &subscriptions)

//        try bankTransferService.save(userData: UserData)
    }

    private func makeItems() -> [any Renderable] {
        let countryCell = BankTransferCountryCellViewItem(
            name: self.currentCountry?.name ?? "",
            flag: self.currentCountry?.emoji ?? "🏴"
        )
        if self.bankTransferService.isBankTransferAvailable() {
            return [
                BankTransferInfoImageCellViewItem(image: .bankTransferInfoAvailableIcon),
                ListSpacerCellViewItem(height: 12, backgroundColor: .clear),
                BankTransferTitleCellViewItem(title: L10n.openIBANAccountForInternationalTransfersWithZeroFees),
                ListSpacerCellViewItem(height: 16, backgroundColor: .clear),
                countryCell,
                ListSpacerCellViewItem(height: 24, backgroundColor: .clear),
                CenterTextCellViewItem(text: L10n.poweredByStriga, style: .text3, color: Color(Asset.Colors.sky.color)),
                ListSpacerCellViewItem(height: 40, backgroundColor: .clear),
                ButtonListCellItem(
                    leadingImage: nil,
                    title: L10n.continue,
                    action: {},
                    style: .primary,
                    trailingImage: Asset.MaterialIcon.arrowRight.image.withTintColor(Asset.Colors.lime.color)
                ),
                ListSpacerCellViewItem(height: 2, backgroundColor: .clear)
            ]
        } else {
            return [
                BankTransferInfoImageCellViewItem(image: .bankTransferInfoUnavailableIcon),
                ListSpacerCellViewItem(height: 27, backgroundColor: .clear),
                BankTransferTitleCellViewItem(title: L10n.thisServiceIsAvailableOnlyForEuropeanEconomicAreaCountries),
                ListSpacerCellViewItem(height: 27, backgroundColor: .clear),
                BankTransferInfoCountriesTextCellViewItem(),
                ListSpacerCellViewItem(height: 26, backgroundColor: .clear),
                countryCell,
                ListSpacerCellViewItem(height: 56, backgroundColor: .clear),
                ButtonListCellItem(
                    leadingImage: nil,
                    title: L10n.changeCountry,
                    action: {},
                    style: .primary,
                    trailingImage: nil
                ),
                ListSpacerCellViewItem(height: 2, backgroundColor: .clear)
            ]
        }
    }

    // MARK: -

    func itemTapped(item: any Identifiable) {
        
    }
    
    // MARK: - actions

    private func openCountries() {
        
    }

}
