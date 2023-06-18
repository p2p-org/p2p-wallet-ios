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
    let isChoosen: (() -> Void)
    
    @GestureState private var isDetectingLongPress = false
    @State private var completedLongPress = false
    
    // MARK: - Body
    
    var body: some View {
        Text("\(number)")
            .font(.system(size: textSize))
            .foregroundColor(Color(isDetectingLongPress ? textColor.tapped : textColor.normal))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(isDetectingLongPress ? customBgColor.tapped : customBgColor.normal))
            .frame(width: size, height: size)
            .cornerRadius(cornerRadius)
            .gesture(longPress)
    }
    
    // MARK: - Methods
    
    private var longPress: some Gesture {
        LongPressGesture(minimumDuration: 3)
            .updating($isDetectingLongPress) { currentState, gestureState,
                transaction in
                gestureState = currentState
            }
            .onEnded { finished in
                completedLongPress = finished
                isChoosen()
            }
    }
}

struct NumpadButton_Previews: PreviewProvider {
    static var previews: some View {
        NumpadButton(number: 1, size: 68) {}
    }
}
