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

    var countrySubmitted: AnyPublisher<Country?, Never> {
        submitCountrySubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    @Injected private var countriesService: CountriesAPI

    // MARK: -

    @Published var items: [any Renderable] = []

    // MARK: -

    private let showCountriesSubject = PassthroughSubject<Country?, Never>()
    private let submitCountrySubject = PassthroughSubject<Country?, Never>()

    private var currentCountry: Country? {
        didSet {
            items = makeItems()
        }
    }

    override init() {
        super.init()

        bind()
    }

    func setCountry(_ country: Country) {
        currentCountry = country
        Defaults.bankTransferLastCountry = country
    }

    func bind() {
        if nil != Defaults.bankTransferLastCountry {
            currentCountry = Defaults.bankTransferLastCountry
        } else {
            Task {
                do {
                    self.currentCountry = try await countriesService.currentCountryName()
                } catch {
                    DefaultLogManager.shared.log(event: "Error", logLevel: .error, data: error.localizedDescription)
                }
            }
        }
    }

    private func makeItems() -> [any Renderable] {
        let countryCell = BankTransferCountryCellViewItem(
            name: currentCountry?.name ?? "",
            flag: currentCountry?.emoji ?? "🏴"
        )
        return [
            BankTransferInfoImageCellViewItem(image: .bankTransferInfoUnavailableIcon),
            ListSpacerCellViewItem(height: 27, backgroundColor: .clear),
            BankTransferTitleCellViewItem(title: L10n.selectYourCountryOfResidence),
            ListSpacerCellViewItem(height: 24, backgroundColor: .clear),
            CenterTextCellViewItem(
                text: L10n.weSuggestPaymentOptionsBasedOnYourChoice,
                style: .text3,
                color: Color(Asset.Colors.night.color)
            ),
            ListSpacerCellViewItem(height: 26, backgroundColor: .clear),
            countryCell,
            ListSpacerCellViewItem(height: 92 + 16, backgroundColor: .clear),
            ButtonListCellItem(
                leadingImage: nil,
                title: L10n.next,
                action: { [weak self] in
                    self?.submitCountry()
                },
                style: .primaryWhite,
                trailingImage: Asset.MaterialIcon.arrowForward.image
            ),
            ListSpacerCellViewItem(height: 48, backgroundColor: .clear)
        ]
    }

    // MARK: -

    func itemTapped(item: any Identifiable) {
        if nil != item as? BankTransferCountryCellViewItem {
            openCountries()
        }
    }

    // MARK: - actions

    private func openCountries() {
        showCountriesSubject.send(currentCountry)
    }

    private func submitCountry() {
        submitCountrySubject.send(currentCountry)
    }
}

extension Country: DefaultsSerializable {}
