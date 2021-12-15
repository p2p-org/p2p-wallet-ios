//
//  SolanaBuyToken.SceneModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.12.21.
//
//

import Foundation
import RxSwift
import RxCocoa

protocol SolanaBuyTokenSceneModel: BESceneModel {}

extension SolanaBuyToken {
    class SceneModel: SolanaBuyTokenSceneModel {
        private let navigationSubject = PublishSubject<NavigatableScene>()
    }
}

extension SolanaBuyToken.SceneModel: BESceneNavigationModel {
    var navigationDriver: Driver<NavigationType> {
        navigationSubject.map { [weak self] scene in
            guard let self = self else { return .none }
            switch scene {
            case .back:
                return .pop
            }
            return .none
        }.asDriver(onErrorJustReturn: .none)
    }
}
