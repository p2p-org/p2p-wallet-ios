//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import Combine
import Foundation
import Resolver

/// ViewModel of `___VARIABLE_scene___` scene
final class ___VARIABLE_scene___ViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies

//    @Injected private var service: ServiceType
    
    // MARK: - Properties
    
    /// Navigation subject (passed from Coordinator)
    let navigation: PassthroughSubject<___VARIABLE_scene___Navigation, Never>
    
//    @Published var model: Model?
//    @Published var isLoading: Bool
    
//    private var modelTask: Task<Void, Never>?
    
    // MARK: - Initializers
    
    init(navigation: PassthroughSubject<___VARIABLE_scene___Navigation, Never>) {
        self.navigation = navigation
        super.init()
        
        // bind subjects
        bind()
        
        // reload
        reload()
    }
    
    // MARK: - Methods
    
    func reload() {
//        isLoading = true
//        modelTask = Task { [unowned self] in
//            let model = try await service.getModel()
//            MainActor.run { [weak self] in
//                self?.isLoading = false
//                self?.model = model
//            }
//        }
    }
    
//    func navigateToDetail() {
//        navigation.send(.detail)
//    }
    
    // MARK: - Helpers
    
    private func bind() {
        
    }
}
