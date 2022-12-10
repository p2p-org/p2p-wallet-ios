//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import Foundation
import SwiftUI

/// View of `___VARIABLE_scene___` scene
struct ___VARIABLE_scene___View: View {
    
    // MARK: - Properties

    /// View model
    @ObservedObject var viewModel: ___VARIABLE_scene___ViewModel
    
    // MARK: - Initializer
    
    init(viewModel: ___VARIABLE_scene___ViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - View content

    /// Body of the view
    var body: some View {
        Text("___VARIABLE_scene___")
    }
}
