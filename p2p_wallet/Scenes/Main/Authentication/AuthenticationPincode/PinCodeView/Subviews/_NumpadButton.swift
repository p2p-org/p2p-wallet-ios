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
    
    let number: Int
    @State private var isHighlighted = false
    
    // MARK: - Body
    
    var body: some View {
        Text("\(number)")
            .font(.system(size: textSize))
            .foregroundColor(Color(isHighlighted ? textColor.tapped : textColor.normal))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(isHighlighted ? customBgColor.tapped : customBgColor.normal))
            .onLongPressGesture {
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

struct _NumpadButton_Previews: PreviewProvider {
    static var previews: some View {
        _NumpadButton(number: 1)
    }
}
