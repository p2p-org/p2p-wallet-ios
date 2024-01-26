import Combine
import Foundation

private enum Constants {
    static let urlString = "https://referral-2ii.pages.dev"
}

final class ReferralProgramViewModel: BaseViewModel, ObservableObject {
    let link: URL

    override init() {
        link = URL(string: Constants.urlString)!
        super.init()
    }
}
