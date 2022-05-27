//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import BEPureLayout
import Foundation

extension ___VARIABLE_scene___ {
    final class ViewController: BEScene {
        // MARK: - Dependencies

        private let viewModel: ViewModel

        // MARK: - Initializer

        init(viewModel: ViewModel) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Methods

        override func build() -> UIView {
            BEVStack(spacing: 8) {
                <#code#>
            }
        }

        override func bind() {
            super.bind()
            viewModel.output.navigatableScene
                .emit(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .detail:
                <#code#>
            case .none:
                break
            }
        }
    }
}
