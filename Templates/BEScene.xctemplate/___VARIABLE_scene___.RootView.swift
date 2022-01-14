//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import UIKit
import RxSwift

extension ___VARIABLE_scene___ {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private var viewModel: ___VARIABLE_scene___ViewModelType
        
        // MARK: - Subviews
        
        // MARK: - Initializer
        init(viewModel: ___VARIABLE_scene___ViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            
        }
        
        // MARK: - Layout
        private func layout() {
            
        }
        
        private func bind() {
            
        }
        
        // MARK: - Actions
        @objc private func showDetail() {
            viewModel.navigate(to: .detail)
        }
    }
}
