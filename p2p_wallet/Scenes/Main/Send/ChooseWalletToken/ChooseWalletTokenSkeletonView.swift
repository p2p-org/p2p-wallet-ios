import SwiftUI
import KeyAppUI
import SkeletonUI

struct ChooseWalletTokenSkeletonView: View {
    var body: some View {
        HStack(spacing: 12) {
            iconPlaceholder
            VStack(alignment: .leading, spacing: 8) {
                textPlaceholder
                textPlaceholder
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .foregroundColor(Color(Asset.Colors.snow.color))
        )
    }

    private var iconPlaceholder: some View {
        Circle()
            .fill(Color(Asset.Colors.rain.color))
            .skeleton(with: true)
            .frame(width: 48, height: 48)
    }

    private var textPlaceholder: some View {
        Capsule()
            .fill(Color(Asset.Colors.rain.color))
            .skeleton(with: true)
            .frame(width: 120, height: 12)
    }
}

