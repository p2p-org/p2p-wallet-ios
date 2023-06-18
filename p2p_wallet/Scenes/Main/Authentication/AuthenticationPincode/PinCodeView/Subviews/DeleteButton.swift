import SwiftUI
import KeyAppUI

struct DeleteButton: View {
    // MARK: - Constant
    
    private let textSize: CGFloat = 32
    private let foregroundColor = Asset.Colors.night.color
    
    // MARK: - State
    
    @GestureState private var isDetectingLongPress = false
    
    // MARK: - Properties

    let size: CGFloat
    var didTap: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        Image(uiImage: Asset.Icons.remove.image.withRenderingMode(.alwaysTemplate))
            .resizable()
            .foregroundColor(Color(isDetectingLongPress ? foregroundColor.withAlphaComponent(0.65) : foregroundColor))
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
            .frame(width: size, height: size)
            .gesture(
                LongPressGesture(minimumDuration: 3)
                    .updating($isDetectingLongPress) { currentState, gestureState,
                        transaction in
                        gestureState = currentState
                    }
                    .onEnded { finished in
                        didTap?()
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

struct DeleteButton_Previews: PreviewProvider {
    static var previews: some View {
        DeleteButton(size: 68)
            .background(Color(.red.withAlphaComponent(0.3)))
    }
}
