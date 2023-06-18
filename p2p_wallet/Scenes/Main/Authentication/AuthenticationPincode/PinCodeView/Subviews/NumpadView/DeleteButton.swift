import SwiftUI
import KeyAppUI

struct DeleteButton: View {
    // MARK: - Constant
    
    private let textSize: CGFloat = 32
    private let foregroundColor = Asset.Colors.night.color
    
    // MARK: - State
    
    @State private var isHighlighting = false
    
    // MARK: - Properties

    let size: CGFloat
    var didTap: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        Image(uiImage: Asset.Icons.remove.image.withRenderingMode(.alwaysTemplate))
            .resizable()
            .foregroundColor(Color(isHighlighting ? foregroundColor.withAlphaComponent(0.65) : foregroundColor))
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
            .frame(width: size, height: size)
            .onTapGesture {
                guard !isHighlighting else { return }
                didTap?()
                isHighlighting = true
                withAnimation {
                    isHighlighting = false
                }
            }
    }
}

struct DeleteButton_Previews: PreviewProvider {
    static var previews: some View {
        DeleteButton(size: 68)
            .background(Color(.red.withAlphaComponent(0.3)))
    }
}
