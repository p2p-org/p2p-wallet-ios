//___FILEHEADER___

import Foundation

extension ___FILEBASENAME___ {
    class SuperViewController: BESuperScene {
        private let viewModel: ___FILEBASENAME___ViewModelType!

        override init() {
            self.viewModel = ViewModel()
            
            super.init()

            viewModel.navigationSignal.emit { [weak self] in self?.navigate(to: $0) }.disposed(by: disposeBag)
        }
        
        override func root() -> UIViewController {
            UIViewController()
        }
    }
}

extension ___FILEBASENAME___.SuperViewController {
    private func navigate(to scene: ___FILEBASENAME___.NavigatableScene) {
        switch scene {}
    }
}
