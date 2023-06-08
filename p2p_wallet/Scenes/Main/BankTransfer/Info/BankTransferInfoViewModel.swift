import BankTransfer
import CountriesAPI
import Combine
import SwiftUI
import SwiftyUserDefaults
import Resolver
import KeyAppUI

final class BankTransferInfoViewModel: BaseViewModel, ObservableObject {

    // MARK: - Navigation

    var showCountries: AnyPublisher<Country?, Never> {
        showCountriesSubject.eraseToAnyPublisher()
    }

    var openRegistration: AnyPublisher<Country, Never> {
        openRegistrationSubject.eraseToAnyPublisher()
    }

    var openProviderInfo: AnyPublisher<URL, Never> {
        openProviderInfoSubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    @Injected private var countriesService: CountriesAPI
    @Injected private var helpLauncher: HelpCenterLauncher

    // MARK: -

    @Published var items: [any Renderable] = []

    // MARK: -

    private let showCountriesSubject = PassthroughSubject<Country?, Never>()
    private let openProviderInfoSubject = PassthroughSubject<URL, Never>()
    private let openRegistrationSubject = PassthroughSubject<Country, Never>()

    @SwiftyUserDefault(keyPath: \.bankTransferLastCountry, options: .cached)
    private var lastChosenCountry: Country?
    private var currentCountry: Country? {
        didSet {
            if lastChosenCountry != currentCountry {
                lastChosenCountry = currentCountry
            }
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
        if nil != lastChosenCountry {
            currentCountry = lastChosenCountry
        } else {
            Task {
                do {
                    self.currentCountry = try await countriesService.currentCountryName()
                } catch {
                    DefaultLogManager.shared.log(error: error)
                }
            }
        }
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
                CenterTextCellViewItem(
                    id: CellItemIdentidier.poweredByStriga.rawValue,
                    text: L10n.poweredByStriga,
                    style: .text3,
                    color: Color(Asset.Colors.sky.color)
                ),
                ListSpacerCellViewItem(height: 40, backgroundColor: .clear),
                ButtonListCellItem(
                    leadingImage: nil,
                    title: L10n.continue,
                    action: { [weak self] in
                        self?.submitCountry()
                    },
                    style: .primary,
                    trailingImage: Asset.MaterialIcon.arrowForward.image.withTintColor(Asset.Colors.lime.color)
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
        } else if let item = item as? CenterTextCellViewItem, item.id == CellItemIdentidier.poweredByStriga.rawValue {
            openProviderInfoSubject.send(URL(string: "https://striga.com")!)
        }
    }

    // MARK: - actions

    private func openCountries() {
        showCountriesSubject.send(currentCountry)
    }

    private func submitCountry() {
        guard let country = self.currentCountry else {
            return
        }
        openRegistrationSubject.send(country)
    }

    private func isAvailable() -> Bool {
        ["at", "be", "bg", "hr", "cy", "cz", "dk", "ee", "fi", "fr", "gr", "es", "nl", "is", "li", "lt", "lu", "lv", "mt", "de", "no", "pl", "pt", "ro", "sk", "si", "se", "hu", "it", "ch", "gb"].contains(self.currentCountry?.code ?? "")
    }

    enum CellItemIdentidier: String {
        case poweredByStriga
    }
}

extension Country: DefaultsSerializable {}
