//
//  BannerTypeTransformer.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 08.11.2021.
//

protocol BannerKindTransformerType: AnyObject {
    func transformBannerKind(
        _: BannerKind,
        closeHandler: @escaping () -> Void,
        selectionHandler: @escaping () -> Void
    ) -> BannerViewContent
}

final class BannerKindTransformer: BannerKindTransformerType {
    func transformBannerKind(
        _ bannerKind: BannerKind,
        closeHandler: @escaping () -> Void,
        selectionHandler: @escaping () -> Void
    ) -> BannerViewContent {
        .init(
            selectionHandler: selectionHandler,
            closeHandler: closeHandler,
            title: chooseTitle(for: bannerKind),
            description: chooseDescription(for: bannerKind)
        )
    }

    private func chooseTitle(for bannerKind: BannerKind) -> String {
        switch bannerKind {
        case .reserveUsername:
            return L10n.reserveYourP2PUsernameNow
        }
    }

    private func chooseDescription(for bannerKind: BannerKind) -> String {
        switch bannerKind {
        case .reserveUsername:
            return L10n.anyTokenCanBeReceivedUsingUsernameRegardlessOfWhetherItIsInYourWalletSList
        }
    }
}
