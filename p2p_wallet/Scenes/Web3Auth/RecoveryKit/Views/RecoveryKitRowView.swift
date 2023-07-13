//
//  RecoveryKitSection.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 02.09.2022.
//

import KeyAppUI
import SwiftUI

struct RecoveryKitRowView: View {
    let icon: ImageResource
    let title: String
    let subtitle: String
    let alert: Bool

    let titleAction: String
    let action: (() -> Void)?

    init(
        icon: ImageResource,
        title: String,
        subtitle: String,
        alert: Bool = false,
        titleAction: String = "",
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.alert = alert
        self.titleAction = titleAction
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(icon)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .fontWeight(.semibold)
                        .apply(style: .text2)
                        .foregroundColor(Color(.night))

                    HStack {
                        if alert {
                            Image(.warningIcon)
                                .foregroundColor(Color(.rose))
                        }
                        Text(subtitle)
                            .apply(style: .label1)
                            .foregroundColor(
                                alert ?
                                    Color(.rose) :
                                    Color(.mountain)
                            )
                    }
                }.padding(.leading, 12)

                Spacer()

                if let action {
                    NewTextButton(title: titleAction, size: .small, style: .second, action: action)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 72)

            // Divider
            Rectangle()
                .fill(Color(.rain))
                .frame(height: 1)
                .edgesIgnoringSafeArea(.horizontal)
                .padding(.leading, 20)
        }
    }
}

struct RecoveryKitRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RecoveryKitRowView(icon: .appleIcon, title: "Apple", subtitle: "dragon@apple.com")
            RecoveryKitRowView(
                icon: .appleIcon,
                title: "Apple",
                subtitle: "dragon@apple.com",
                alert: true,
                titleAction: "Manage"
            ) {}
        }
    }
}
