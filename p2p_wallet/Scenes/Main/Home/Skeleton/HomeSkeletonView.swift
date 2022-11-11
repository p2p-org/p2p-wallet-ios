//
//  HomeSkeletonView.swift
//  p2p_wallet
//
//  Created by Ivan on 13.10.2022.
//

import KeyAppUI
import SkeletonUI
import SwiftUI

struct HomeSkeletonView: View {
    var body: some View {
        NavigationView {
            content
                .padding(.top, 11)
                .navigationBarTitleDisplayMode(.inline)
                .navigationViewStyle(StackNavigationViewStyle())
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("")
                            .skeleton(
                                with: true,
                                size: CGSize(width: 164, height: 40),
                                animated: .default
                            )
                    }
                }
        }
    }

    private var content: some View {
        VStack(spacing: 44) {
            VStack(spacing: 0) {
                Text("")
                    .skeleton(
                        with: true,
                        size: CGSize(width: 200, height: 32),
                        animated: .default
                    )
                    .padding(.top, 24)
                Text("")
                    .skeleton(
                        with: true,
                        size: CGSize(width: 128, height: 28),
                        animated: .default
                    )
                    .padding(.top, 12)
                actions
                    .padding(.vertical, 32)
            }
            .frame(maxWidth: .infinity)
            .background(Color(Asset.Colors.smoke.color))
            VStack(alignment: .leading, spacing: 0) {
                Text("")
                    .skeleton(
                        with: true,
                        size: CGSize(width: 128, height: 28),
                        animated: .default
                    )
                    .padding(.bottom, 12)
                cell
                cell
            }
            .padding(.horizontal, 16)
            Spacer()
        }
    }

    private var actions: some View {
        HStack(spacing: 32) {
            ForEach(1 ... 4, id: \.self) { _ in
                action
            }
        }
    }

    private var action: some View {
        VStack(spacing: 12) {
            Text("")
                .skeleton(
                    with: true,
                    size: CGSize(width: 52, height: 44),
                    animated: .default
                )
            Text("")
                .skeleton(
                    with: true,
                    size: CGSize(width: 52, height: 20),
                    animated: .default
                )
        }
    }

    private var cell: some View {
        HStack(spacing: 12) {
            Text("")
                .skeleton(
                    with: true,
                    size: CGSize(width: 48, height: 48),
                    animated: .default
                )
            VStack(spacing: 8) {
                ForEach(1 ... 2, id: \.self) { _ in
                    Text("")
                        .skeleton(
                            with: true,
                            size: CGSize(width: 108, height: 12),
                            animated: .default
                        )
                }
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }
}
