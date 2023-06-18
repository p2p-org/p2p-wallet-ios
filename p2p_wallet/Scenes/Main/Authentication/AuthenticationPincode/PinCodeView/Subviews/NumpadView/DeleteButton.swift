import SwiftUI
import KeyAppUI

/// A view representing a delete button.
struct DeleteButton: View {
    // MARK: - Constants
    
    /// The text size for the delete icon.
    private let textSize: CGFloat = 32
    
    /// The foreground color of the delete icon.
    private let foregroundColor = Asset.Colors.night.color
    
    // MARK: - State
    
    /// Indicates whether the button is currently being highlighted.
    @State private var isHighlighting = false
    
    // MARK: - Properties
    
    /// The size of the button.
    let size: CGFloat
    
    /// The closure called when the button is tapped.
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
