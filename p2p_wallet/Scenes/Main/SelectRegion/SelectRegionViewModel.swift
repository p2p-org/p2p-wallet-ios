import BankTransfer
import CountriesAPI
import Combine
import SwiftUI
import SwiftyUserDefaults
import Resolver
import KeyAppUI

final class SelectRegionViewModel: BaseViewModel, ObservableObject {

    // MARK: - Navigation

    var showCountries: AnyPublisher<Region?, Never> {
        showCountriesSubject.eraseToAnyPublisher()
    }

    var countrySubmitted: AnyPublisher<Region?, Never> {
        submitCountrySubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    @Injected private var countriesService: CountriesAPI

    // MARK: -

    @Published var items: [any Renderable] = []
    @Published var isLoading = false {
       didSet {
           items = makeItems()
       }
   }

    // MARK: -

    private let showCountriesSubject = PassthroughSubject<Region?, Never>()
    private let submitCountrySubject = PassthroughSubject<Region?, Never>()

    private var currentRegion: Region? {
        didSet {
            items = makeItems()
        }
    }

    override init() {
        super.init()

        bind()
    }

    func setRegion(_ country: Region) {
        currentRegion = country
        Defaults.region = country
    }

    func bind() {
        if nil != Defaults.region {
            currentRegion = Defaults.region
        } else {
            Task {
                defer {
                    self.isLoading = false
                }

                self.isLoading = true
                do {
                    self.currentRegion = try await countriesService.currentCountryName()
                } catch {
                    DefaultLogManager.shared.log(event: "Error", logLevel: .error, data: error.localizedDescription)
                }
            }
        }
    }

    private func makeItems() -> [any Renderable] {
        let countryCell = BankTransferCountryCellViewItem(
            name: currentRegion?.name ?? "",
            flag: currentRegion?.flagEmoji?.decodeHTMLEntities() ?? "🏴",
            isLoading: isLoading
        )
        return [
            BankTransferInfoImageCellViewItem(image: .bankTransferInfoUnavailableIcon),
            ListSpacerCellViewItem(height: 27, backgroundColor: .clear),
            BankTransferTitleCellViewItem(title: L10n.selectYourCountryOfResidence),
            ListSpacerCellViewItem(height: 27, backgroundColor: .clear),
            CenterTextCellViewItem(
                text: L10n.weSuggestPaymentOptionsBasedOnYourChoice,
                style: .text3,
                color: Color(Asset.Colors.night.color)
            ),
            ListSpacerCellViewItem(height: 26, backgroundColor: .clear),
            countryCell,
            ListSpacerCellViewItem(height: 92 + 21, backgroundColor: .clear),
            ButtonListCellItem(
                leadingImage: nil,
                title: L10n.next,
                action: { [weak self] in
                    self?.submitCountry()
                },
                style: .primaryWhite,
                trailingImage: Asset.MaterialIcon.arrowForward.image
            ),
            ListSpacerCellViewItem(height: 53, backgroundColor: .clear)
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
        showCountriesSubject.send(currentRegion)
    }

    private func submitCountry() {
        Defaults.region = currentRegion
        submitCountrySubject.send(currentRegion)
    }
}
