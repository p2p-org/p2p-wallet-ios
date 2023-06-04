//
//  DeviceMigrationView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03/06/2023.
//

import KeyAppUI
import SwiftUI

struct DeviceShareMigrationView: View {
    var body: some View {
        ExplainLayoutView {
            VStack {
                Image(uiImage: UIImage.easyToStart)
                    .resizable()
                    .frame(width: 200, height: 150)

                Text("You can up to date \n your device ")
                    .fontWeight(.bold)
                    .apply(style: .title1)
                    .padding(.bottom, 48)
                    .multilineTextAlignment(.center)
            }
        } content: {
            VStack {
                VStack(alignment: .leading,spacing: 12) {
                    Text("We've noticed that you're using a new device.")
                        .apply(style: .text3)
                        .frame(alignment: .leading)
                    Text(
                        "We suggest setting up Xiaomi 13 Lite as the current device and using it when restoring your account."
                    )
                    .apply(style: .text3)
                    Text("We've noticed that you're using a new device.")
                        .apply(style: .text3)
                }
                .padding(.top, 52)
                .padding(.leading,12)

                Spacer()

                BottomActionContainer {
                    VStack {
                        NewTextButton(title: "Update device", style: .inverted) {}
                            .padding(.bottom, 12)
                        NewTextButton(title: "Skip", style: .outlineWhite) {}
                    }
                }
            }
        } hint: {
            Text("Redmi 8")
                .font(.system(size: 17))
                .padding(12)
                .background(Color.white)
                .border(Color(Asset.Colors.rain.color))
                .cornerRadius(radius: 24, corners: .allCorners)
                .offset(y: 24)
        }
        .ignoresSafeArea()
    }
}

struct DeviceShareMigrationView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceShareMigrationView()
    }
}
