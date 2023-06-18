import SwiftUI
import KeyAppUI

/// Represents the colors for different states of a pincode button.
struct PincodeStateColor {
    /// The color for the normal state of the pincode button.
    let normal: UIColor
    
    /// The color for the tapped state of the pincode button.
    let tapped: UIColor
}

/// A view representing a numpad button for pincode input.
struct NumpadButton: View {
    // MARK: - Constants
    
    /// The text size for the number displayed on the button.
    private let textSize: CGFloat = 32
    
    /// The custom background color for the button in different states.
    private let customBgColor = PincodeStateColor(normal: .clear, tapped: Asset.Colors.night.color)
    
    /// The text color for the number displayed on the button in different states.
    private let textColor = PincodeStateColor(normal: Asset.Colors.night.color, tapped: Asset.Colors.snow.color)
    
    /// The corner radius of the button.
    let cornerRadius: CGFloat = 20
    
    // MARK: - Properties
    
    /// The number displayed on the button.
    let number: Int
    
    /// The size of the button.
    let size: CGFloat
    
    /// The closure called when the button is tapped.
    var didTap: (() -> Void)?
    
    // MARK: - State
    
    /// Indicates whether the button is currently being highlighted.
    @State private var isHighlighting = false
    
    // MARK: - Body
    
    var body: some View {
        Text("\(number)")
            .font(.system(size: textSize))
            .foregroundColor(Color(isHighlighting ? textColor.tapped : textColor.normal))
            .frame(width: size, height: size)
            .background(Color(isHighlighting ? customBgColor.tapped : customBgColor.normal))
            .cornerRadius(cornerRadius)
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

struct NumpadButton_Previews: PreviewProvider {
    static var previews: some View {
        NumpadButton(number: 1, size: 68) {}
    }
}
