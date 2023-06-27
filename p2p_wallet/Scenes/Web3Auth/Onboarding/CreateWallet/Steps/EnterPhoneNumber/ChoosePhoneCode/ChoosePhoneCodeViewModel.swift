import Combine
import CountriesAPI
import PhoneNumberKit

final class ChoosePhoneCodeViewModel: BaseViewModel, ObservableObject {

    // MARK: - Properties

    private var cachedResult = [SelectableCountry]()
    private var initialDialCode: String?
    private var initialCountryCode: String?

    @Published var selectedDialCode: String?
    @Published var selectedCountryCode: String?
    @Published var keyword = ""
    @Published var isSearchFieldFocused = false
    @Published var data = [SelectableCountry]()
    let didClose = PassthroughSubject<Void, Never>()

    // MARK: - Initializers

    init(selectedDialCode: String?, selectedCountryCode: String?) {
        initialDialCode = selectedDialCode
        initialCountryCode = selectedCountryCode
        super.init()
        Task {
            self.data = try await createRequest()
        }
        bind()
    }

    // MARK: - Methods
    func select(country: SelectableCountry) {
        guard !country.isSelected, !country.isEmpty else { return }
        selectedDialCode = country.value.dialCode
        selectedCountryCode = country.value.code
        var countries = data
        for i in 0 ..< countries.count {
            if countries[i].value.dialCode == country.value.dialCode,
               countries[i].value.code == country.value.code
            {
                countries[i].isSelected = true
            } else {
                countries[i].isSelected = false
            }
        }
        data = countries
    }

    private func bind() {
        $keyword
            .sink { [weak self] keyword in
                guard let self = self else { return }
                if keyword.isEmpty {
                    let cachedResult = self.cachedResult
                    self.data = self.placeInitialIfNeeded(countries: cachedResult)
                    return
                }
                var newData = self.cachedResult.filteredAndSorted(byKeyword: keyword)
                if newData.isEmpty {
                    newData.append(self.emptyCountryModel())
                } else {
                    newData = self.placeInitialIfNeeded(countries: newData)
                }
                self.data = newData
            }
            .store(in: &subscriptions)

        var selectedIndex = 0
        $selectedDialCode.sink { [weak self] value in
            guard let value = value else { return }

            if let index = (self?.cachedResult
                .firstIndex { $0.value.dialCode == self?.initialDialCode && $0.value.code == self?.initialCountryCode
                })
            {
                self?.cachedResult[index].isSelected = false
            }
            self?.initialDialCode = nil

            if let index = (self?.cachedResult.firstIndex { $0.value.dialCode == value }) {
                self?.cachedResult[selectedIndex].isSelected = false
                self?.cachedResult[index].isSelected = true
                selectedIndex = index
            }
        }
        .store(in: &subscriptions)
    }

    private func createRequest() async throws -> [SelectableCountry] {
        let selectedDialCode = selectedDialCode ?? initialDialCode
        let selectedCountryCode = selectedCountryCode ?? initialCountryCode
        cachedResult = try await CountriesAPIImpl().fetchCountries()
            .map { .init(value: $0, isSelected: $0.dialCode == selectedDialCode && $0.code == selectedCountryCode) }
        var countries = cachedResult.filteredAndSorted(byKeyword: keyword)
        countries = placeInitialIfNeeded(countries: countries)
        return countries
    }

    private func emptyCountryModel() -> SelectableCountry {
        SelectableCountry(
            value: Country(name: L10n.sorryWeDonTKnowASuchCountry, code: "", dialCode: "", emoji: "🏴"),
            isSelected: false,
            isEmpty: true
        )
    }

    private func placeInitialIfNeeded(countries: [SelectableCountry]) -> [SelectableCountry] {
        var countries = countries.filteredAndSorted()
        guard initialDialCode != nil, initialCountryCode != nil else { return countries }
        // Put initial selected country in the first place
        if let selectedIndex = countries
            .firstIndex(where: { $0.value.dialCode == initialDialCode && $0.value.code == initialCountryCode })
        {
            let selectedCountry = countries.remove(at: selectedIndex)
            countries.insert(selectedCountry, at: .zero)
        }
        return countries
    }
}