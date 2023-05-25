import BankTransfer
import CountriesAPI
import Combine
import SwiftUI
import Resolver
import KeyAppUI

final class BankTransferInfoViewModel: BaseViewModel, ObservableObject {

    // MARK: -

    var showCountries: AnyPublisher<Country?, Never> {
        showCountriesSubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    @Injected private var bankTransferService: BankTransferService
    @Injected private var countriesService: CountriesAPI
    @Injected private var helpLauncher: HelpCenterLauncher

    // MARK: -

    @Published var items: [any Renderable] = []

    // MARK: -

    private var showCountriesSubject = PassthroughSubject<Country?, Never>()
    private var currentCountry: Country? {
        didSet {
            self.items = self.makeItems()
        }
    }

    override init() {
        super.init()

        bind()
    }

    func setCountry(_ country: Country) {
        self.currentCountry = country
    }

    func bind() {
        Task {
            do {
                self.currentCountry = try await countriesService.currentCountryName()
            } catch {
                DefaultLogManager.shared.log(error: error)
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
        if isAvailable() {
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
                    action: { [weak self] in
                        self?.submitCountry()
                    },
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
                    action: { [weak self] in
                        self?.openCountries()
                    },
                    style: .primary,
                    trailingImage: nil
                ),
                ListSpacerCellViewItem(height: 2, backgroundColor: .clear)
            ]
        }
    }

    // MARK: -

    func itemTapped(item: any Identifiable) {
        if nil != item as? BankTransferInfoCountriesTextCellViewItem {
            helpLauncher.launch()
        } else if nil != item as? BankTransferCountryCellViewItem {
            openCountries()
        }
    }

    // MARK: - actions

    private func openCountries() {
        showCountriesSubject.send(currentCountry)
    }

    private func submitCountry() {
        guard let code = self.currentCountry?.code else {
            return
        }
        do {
            try self.bankTransferService.set(countryCode: code)
        } catch {
            DefaultLogManager.shared.log(error: error)
        }
    }

    private func isAvailable() -> Bool {
        ["at", "be", "bg", "hr", "cy", "cz", "dk", "ee", "fi", "fr", "gr", "es", "nl", "is", "li", "lt", "lu", "lv", "mt", "de", "no", "pl", "pt", "ro", "sk", "si", "se", "hu", "it", "ch", "gb"].contains(self.currentCountry?.code ?? "")
    }

}
