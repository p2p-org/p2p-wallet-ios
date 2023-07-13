import SwiftUI
import KeyAppUI

struct ChooseItemSearchableItemLoadingView: View {
    var body: some View {
        VStack {
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
                    .foregroundColor(Color(.snow))
            )
            .padding(.top, 44)
            .frame(height: 88)
            .padding(.horizontal, 16)
            Spacer()
        }
    }

    private var iconPlaceholder: some View {
        Circle()
            .fill(Color(.rain))
            .skeleton(with: true)
            .frame(width: 48, height: 48)
    }

    private var textPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(.rain))
            .skeleton(with: true)
            .frame(width: 120, height: 12)
    }
}
