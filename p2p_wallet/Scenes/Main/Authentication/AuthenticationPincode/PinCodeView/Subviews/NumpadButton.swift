import SwiftUI
import KeyAppUI

struct PincodeStateColor {
    let normal: UIColor
    let tapped: UIColor
}

struct NumpadButton: View {
    // MARK: - Constant
    
    private let textSize: CGFloat = 32
    private let customBgColor = PincodeStateColor(normal: .clear, tapped: Asset.Colors.night.color)
    private let textColor = PincodeStateColor(normal: Asset.Colors.night.color, tapped: Asset.Colors.snow.color)
    let cornerRadius: CGFloat = 20
    
    // MARK: - State

    let number: Int
    let size: CGFloat
    var didTap: (() -> Void)?
    
    @GestureState private var isDetectingLongPress = false
    
    // MARK: - Body
    
    var body: some View {
        Text("\(number)")
            .font(.system(size: textSize))
            .foregroundColor(Color(isDetectingLongPress ? textColor.tapped : textColor.normal))
            .frame(width: size, height: size)
            .background(Color(isDetectingLongPress ? customBgColor.tapped : customBgColor.normal))
            .cornerRadius(cornerRadius)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.3)
                    .updating($isDetectingLongPress) { currentState, gestureState,
                        transaction in
                        gestureState = currentState
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        didTap?()
                    }
            )
    }
}

struct NumpadButton_Previews: PreviewProvider {
    static var previews: some View {
        NumpadButton(number: 1, size: 68) {}
    }
}
