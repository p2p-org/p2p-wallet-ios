import SwiftUI
import KeyAppUI

/// A view representing a numpad for entering numbers.
struct NumpadView: View {
    
    // MARK: - Constants
    
    /// The size of the numpad buttons.
    private let buttonSize: CGFloat = 68
    
    /// The horizontal spacing between numpad buttons.
    private let spacing: CGFloat = 42
    
    /// The vertical spacing between rows of numpad buttons.
    private let vSpacing: CGFloat = 12
    
    // MARK: - Properties
    
    /// The color of the delete button.
    @State private var deleteButtonColor = Color(Asset.Colors.night.color)
    
    /// Indicates whether to show the biometry button.
    let showBiometry: Bool
    
    /// Indicates whether the delete button is hidden.
    let isDeleteButtonHidden: Bool
    
    /// Indicates whether the numpad is locked.
    let isLocked: Bool
    
    /// The closure called when a number button is tapped.
    var didChooseNumber: ((Int) -> Void)?
    
    /// The closure called when the delete button is tapped.
    var didTapDelete: (() -> Void)?
    
    /// The closure called when the biometry button is tapped.
    var didTapBiometry: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: vSpacing) {
            HStack(spacing: spacing) {
                ForEach(1...3, id: \.self) {
                    numpadButton($0)
                }
            }
            
            HStack(spacing: spacing) {
                ForEach(4...6, id: \.self) {
                    numpadButton($0)
                }
            }
            
            HStack(spacing: spacing) {
                ForEach(7...9, id: \.self) {
                    numpadButton($0)
                }
            }
            HStack(spacing: spacing) {
                if showBiometry {
                    Button(action: {
                        guard !isLocked else { return }
                        didTapBiometry?()
                    }, label: {
                        Image(uiImage: .faceId)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .padding((buttonSize - 32) / 2)
                    })
                } else {
                    Spacer().frame(width: buttonSize, height: buttonSize)
                }
                
                numpadButton(0)
                DeleteButton(size: buttonSize) {
                    guard !isLocked else { return }
                    didTapDelete?()
                }
                .opacity(isDeleteButtonHidden ? 0: 1)
            }
        }
    }
    
    /// Creates a numpad button for the specified number.
    ///
    /// - Parameters:
    ///   - number: The number to display on the button.
    /// - Returns: A `NumpadButton` representing the numpad button.
    private func numpadButton(_ number: Int) -> NumpadButton {
        NumpadButton(number: number, size: buttonSize) {
            guard !isLocked else { return }
            didChooseNumber?(number)
        }
    }
}

struct NumpadView_Previews: PreviewProvider {
    static var previews: some View {
        NumpadView(
            showBiometry: true,
            isDeleteButtonHidden: false,
            isLocked: false
        )
    }
}
