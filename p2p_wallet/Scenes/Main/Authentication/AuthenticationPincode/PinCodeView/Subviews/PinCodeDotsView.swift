import SwiftUI
import KeyAppUI

/// A view representing the dots for displaying pin code digits.
struct PinCodeDotsView: View {
    // MARK: - Constants
    
    /// The size of the dots.
    private let dotSize: CGFloat = 12.adaptiveHeight
    
    /// The padding around the dots.
    private let padding: EdgeInsets = .init(
        top: 8.adaptiveHeight,
        leading: 13.adaptiveHeight,
        bottom: 8.adaptiveHeight,
        trailing: 13.adaptiveHeight
    )
    
    /// The default color for the dots.
    private let defaultColor = Asset.Colors.night.color.withAlphaComponent(0.3)
    
    /// The color for the dots in the highlight state.
    private let highlightColor = Asset.Colors.night.color
    
    /// The color for the dots in the error state.
    private let errorColor = Asset.Colors.rose.color
    
    /// The color for the dots in the success state.
    private let successColor = Asset.Colors.mint.color
    
    // MARK: - Properties
    
    /// The current number of digits entered.
    var numberOfDigits: Int
    
    /// The length of the pin code.
    let pincodeLength: Int
    
    /// Indicates whether the view is presenting an error state.
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
