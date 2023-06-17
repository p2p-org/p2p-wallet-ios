import SwiftUI
import KeyAppUI

struct PincodeStateColor {
    let normal: UIColor
    let tapped: UIColor
}

struct _NumpadButton: View {
    // MARK: - Constant
    
    private let textSize: CGFloat = 32
    private let customBgColor = PincodeStateColor(normal: .clear, tapped: Asset.Colors.night.color)
    private let textColor = PincodeStateColor(normal: Asset.Colors.night.color, tapped: Asset.Colors.snow.color)
    
    // MARK: - State
    
    @State private var isHighlighted = false
    
    // MARK: - Body
    
    var body: some View {
        Text("")
            .font(.system(size: textSize))
            .foregroundColor(Color(isHighlighted ? textColor.tapped : textColor.normal))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(isHighlighted ? customBgColor.tapped : customBgColor.normal))
            .onTapGesture {
                animateTapping()
            }
    }
    
    // MARK: - Methods
    
    private func setHighlight(value: Bool) {
        isHighlighted = value
    }
    
    private func animateTapping() {
        setHighlight(value: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            setHighlight(value: false)
        }
    }
}
