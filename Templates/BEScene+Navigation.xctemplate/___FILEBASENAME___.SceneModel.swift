//___FILEHEADER___

import Foundation

protocol ___FILEBASENAME___SceneModel: BESceneModel {}

extension ___FILEBASENAME___ {
    class SceneModel: ___FILEBASENAME___SceneModel {
        private let navigationSubject = PublishSubject<NavigatableScene>()
    }
}

extension ___FILEBASENAME___.SceneModel: BESceneNavigationModel {
    var navigationDriver: Driver<NavigationType> {
        navigationSubject.map { [weak self] scene in
            guard let self = self else { return .none }
            switch scene {}
            return .none
        }.asDriver(onErrorJustReturn: .none)
    }
}
