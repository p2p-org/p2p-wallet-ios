//___FILEHEADER___

import Foundation

protocol ___FILEBASENAME___ViewModelType {
    var navigationSignal: Signal<___FILEBASENAME___.NavigatableScene> { get }
}

extension ___FILEBASENAME___ {
    class ViewModel {
        private let navigationSubject = Signal<NavigatableScene>()
    }
}

extension ___FILEBASENAME___.ViewModel: ___FILEBASENAME___ViewModelType {
    var navigationSignal: Signal<___FILEBASENAME___.NavigatableScene> {
        navigationSubject.asSignal()
    }
}
