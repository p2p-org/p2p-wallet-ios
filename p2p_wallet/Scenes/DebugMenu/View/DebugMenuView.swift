//
//  DebugMenuView.swift
//  p2p_wallet
//
//  Created by Ivan on 14.06.2022.
//

import SwiftUI

struct DebugMenuView: View {
    @ObservedObject private var viewModel: DebugMenuViewModel
    @ObservedObject private var onboardingConfig = OnboardingConfig.shared

    init(viewModel: DebugMenuViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            List {
                Toggle("Network Logger", isOn: $viewModel.networkLoggerVisible)
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

                Section(header: Text("Onboarding configurations")) {
                    TextFieldRow(title: "Metadata:", content: $onboardingConfig.metaDataEndpoint)
                    TextFieldRow(title: "Torus:", content: $onboardingConfig.torusEndpoint)
                    TextFieldRow(title: "Google:", content: $onboardingConfig.torusGoogleVerifier)
                    TextFieldRow(title: "Apple", content: $onboardingConfig.torusAppleVerifier)
                    TextFieldRow(title: "MockDeviceShare:", content: $onboardingConfig.mockDeviceShare)
                        .disabled(viewModel.features.first(where: { $0.feature == .mockedDeviceShare })?.isOn == false)
                        .foregroundColor(viewModel.features.first(where: { $0.feature == .mockedDeviceShare })?
                            .isOn == false ? Color.gray : Color.black)
                }
            }
            .navigationBarTitle("Debug Menu", displayMode: .inline)
        }
    }
}

private struct TextFieldRow: View {
    let title: String
    let content: Binding<String>

    var body: some View {
        HStack {
            Text(title)
            TextEditor(text: content)
        }
    }
}
