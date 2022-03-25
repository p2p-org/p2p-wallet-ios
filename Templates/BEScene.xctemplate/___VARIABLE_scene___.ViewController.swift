//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import Foundation
import UIKit

extension ___VARIABLE_scene___ {
    class ViewController: BEScene {
        // MARK: - Dependencies
        let viewModel: ___VARIABLE_scene___ViewModelType
        
        // MARK: - Properties
        
        // MARK: - Initializer
        init(viewModel: ___VARIABLE_scene___ViewModelType) {
            self.viewModel = viewModel
        }
        
        // MARK: - Methods
        override func build() -> UIView {
            BEContainer {}
        }
        
        override func setUp() {
            super.setUp()
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {return}
            switch scene {
            case .detail:
//                let vc = Detail.ViewController()
//                present(vc, completion: nil)
                break
            }
        }
    }
}
