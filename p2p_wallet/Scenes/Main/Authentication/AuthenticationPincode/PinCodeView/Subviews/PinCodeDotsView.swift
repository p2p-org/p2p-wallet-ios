import SwiftUI
import KeyAppUI

struct PinCodeDotsView: View {
    // MARK: - Constants
    
    private let dotSize: CGFloat = 12.adaptiveHeight
    private let padding: EdgeInsets = .init(
        top: 8.adaptiveHeight,
        leading: 13.adaptiveHeight,
        bottom: 8.adaptiveHeight,
        trailing: 13.adaptiveHeight
    )
    
    /// Default color for dots
    private let defaultColor = Asset.Colors.night.color.withAlphaComponent(0.3)
    /// Color for highlight state
    private let highlightColor = Asset.Colors.night.color
    /// Color for error state
    private let errorColor = Asset.Colors.rose.color
    /// Color for success state
    private let successColor = Asset.Colors.mint.color
    
    // MARK: - Properties
    
    var numberOfDigits: Int
    let pincodeLength: Int
    let isPresentingError: Bool
    
    // MARK: - View Body
    
    var body: some View {
        let colorForIndex: (Int) -> UIColor = { index in
            if isPresentingError { return errorColor }
            return index < numberOfDigits ? highlightColor : defaultColor
        }
        return VStack {
            HStack(spacing: padding.leading) {
                ForEach(0..<pincodeLength, id: \.self) { index in
                    Circle()
                        .fill(Color(colorForIndex(index)))
                        .frame(width: dotSize, height: dotSize)
                        .cornerRadius(dotSize / 2)
                }
            }
            .padding(padding)
        }
    }
}

struct PinCodeDotsView_Previews: PreviewProvider {
    //A view which will wraps the actual view and holds state variable.
    struct ContainerView: View {
        @State private var numberOfDigits: Int = 0
        let pincodeLength: Int
        
        var body: some View {
            VStack {
                PinCodeDotsView(
                    numberOfDigits: numberOfDigits,
                    pincodeLength: pincodeLength,
                    isPresentingError: false
                )
                Button("Tap here") {
                    if numberOfDigits == pincodeLength {
                        numberOfDigits = 0
                    } else {
                        numberOfDigits += 1
                    }
                }
            }
        }
    }
    
    static var previews: some View {
        ContainerView(pincodeLength: 8)
    }
}
