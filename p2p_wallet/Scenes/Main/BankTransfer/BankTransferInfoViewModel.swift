import BankTransfer
import SwiftUI
import Foundation
import Resolver
import KeyAppUI

final class BankTransferInfoViewModel: BaseViewModel, ObservableObject {

    // MARK: - Dependencies

    @Injected private var bankTransferService: BankTransferService

    // MARK: -

    @Published var items: [any Renderable] = []
    
    // MARK: -

    override init() {
        super.init()

        bind()
    }

    func bind() {
        bankTransferService.userData.map { _ in
            if self.bankTransferService.isBankTransferAvailable() {
                return [
                    BankTransferInfoImageViewCellItem(image: .bankTransferInfoAvailableIcon),
                    BankTransferTitleCellItem(title: L10n.openIBANAccountForInternationalTransfersWithZeroFees),
                    ListSpacerCellViewItem(height: 16, backgroundColor: .clear),
                    BankTransferCountryCellItem(
                        name: "Estonia",
                        flag: "🇪🇪"
                    ),
                    ListSpacerCellViewItem(height: 24, backgroundColor: .clear),
                    CenterTextCellItem(text: L10n.poweredByStriga, style: .text3, color: Color(Asset.Colors.sky.color)),
                    ListSpacerCellViewItem(height: 40, backgroundColor: .clear),
                    
                ]
            } else {
                return [
                    BankTransferInfoImageViewCellItem(image: .bankTransferInfoUnavailableIcon),
                    BankTransferTitleCellItem(title: L10n.thisServiceIsAvailableOnlyForEuropeanEconomicAreaCountries),
                    ListSpacerCellViewItem(height: 16, backgroundColor: .clear),
                    BankTransferCountryCellItem(
                        name: "Estonia",
                        flag: "🇪🇪"
                    )
                ]
            }
        }.assignWeak(to: \.items, on: self).store(in: &subscriptions)

//        try bankTransferService.save(userData: UserData)
    }

}
