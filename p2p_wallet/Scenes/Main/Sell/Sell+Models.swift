import Foundation
import Sell

enum SellNavigation {
    case webPage(url: URL)
    case showPending(transactions: [SellDataServiceTransaction], fiat: any ProviderFiat)
    case moonpayInfo
    case chooseCountry(SelectCountryViewModel.Model)
}

enum SellDataViewStatus {
    case loading
    case ready
    case error(SellViewModelDataError)
}

enum SellViewModelDataError {
    case region(ChangeCountryErrorView.ChangeCountryModel)
    case other
}
