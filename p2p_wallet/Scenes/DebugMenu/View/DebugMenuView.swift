//
//  DebugMenuView.swift
//  p2p_wallet
//
//  Created by Ivan on 14.06.2022.
//

import SwiftUI

struct DebugMenuView: View {
    @ObservedObject private var viewModel: DebugMenuViewModel

    init(viewModel: DebugMenuViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            List {
                Toggle("Network Logger", isOn: $viewModel.networkLoggerVisible)
                Section(header: Text("Feature Toggles")) {
                    ForEach(viewModel.features.indices) { index in
                        if let feature = viewModel.features[index].feature {
                            Toggle(viewModel.features[index].title, isOn: $viewModel.features[index].isOn)
                                .valueChanged(value: viewModel.features[index].isOn) { newValue in
                                    viewModel.setFeature(feature, isOn: newValue)
                                }
                        } else {
                            Text(viewModel.features[index].title)
                        }
                    }
                }
            }
            .navigationBarTitle("Debug Menu", displayMode: .inline)
        }
    }
}
