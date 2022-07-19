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
                Section(header: Text("Url Toggles")) {
                    ForEach(0 ..< viewModel.urlToggles.count, id: \.self) { index in
                        Picker(
                            viewModel.urlToggles[index].title,
                            selection: $viewModel.urlToggles[index].currentConfigPart
                        ) {
                            ForEach(viewModel.urlToggles[index].configParts, id: \.self) { configPath in
                                Text(configPath)
                            }
                        }
                        .valueChanged(value: viewModel.urlToggles[index].currentConfigPart) { newValue in
                            viewModel.setCurrentConfigPath(newValue, for: viewModel.urlToggles[index])
                        }
                    }
                }
                Section(header: Text("Feature Toggles")) {
                    ForEach(0 ..< viewModel.features.count, id: \.self) { index in
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
