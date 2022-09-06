//
//  NetworkView.swift
//  p2p_wallet
//
//  Created by Ivan on 31.08.2022.
//

import KeyAppUI
import SwiftUI

struct NetworkView: View {
    @ObservedObject var viewModel: NetworkViewModel

    @State private var lastClickedIndex = 0
    @State private var alertPresented = false

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 18) {
                Color(Asset.Colors.rain.color)
                    .frame(width: 31, height: 4)
                    .cornerRadius(2)
                Text(L10n.network)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .title3, weight: .semibold))
            }
            VStack {
                VStack(spacing: 0) {
                    ForEach(viewModel.endPoints.indices, id: \.self) { index in
                        cell(
                            index: index,
                            title: viewModel.endPoints[index].address,
                            withSeparator: index < viewModel.endPoints.count - 1,
                            selected: index == 0
                        )
                    }
                }
                Spacer()
                Button(
                    action: {
                        viewModel.cancel()
                    },
                    label: {
                        Text(L10n.done)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .font(uiFont: .font(of: .text2, weight: .semibold))
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                            .background(Color(Asset.Colors.rain.color))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                    }
                )
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 16)
    }

    private func cell(index: Int, title: String, withSeparator: Bool, selected: Bool) -> some View {
        Button(
            action: {
                if !selected {
                    lastClickedIndex = index
                    alertPresented.toggle()
                }
            },
            label: {
                VStack(spacing: -1) {
                    HStack {
                        Text(title)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .font(uiFont: .font(of: .text2))
                        Spacer()
                        if selected {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 16)
                    if withSeparator {
                        Color(Asset.Colors.rain.color)
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                            .padding(.leading, 20)
                    }
                }
            }
        )
            .alert(isPresented: $alertPresented) {
                Alert(
                    title: Text(L10n.switchNetwork),
                    message: Text(
                        L10n.doYouReallyWantToSwitchTo + " \"" + viewModel.endPoints[lastClickedIndex].address + "\""
                    ),
                    primaryButton: .cancel(Text(L10n.ok)) {
                        viewModel.setEndPoint(viewModel.endPoints[lastClickedIndex])
                    },
                    secondaryButton: .default(Text(L10n.cancel))
                )
            }
    }
}
