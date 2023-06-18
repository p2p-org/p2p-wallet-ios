import SwiftUI
import KeyAppUI

struct NumpadView: View {

    // MARK: - Constants

    private let buttonSize: CGFloat = 68
    private let spacing: CGFloat = 42
    private let vSpacing: CGFloat = 12

    // MARK: - Properties

    @State private var deleteButtonColor = Color(Asset.Colors.night.color)
    
    var didChooseNumber: ((Int) -> Void)?
    var didTapDelete: (() -> Void)?

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
                Spacer().frame(width: 68, height: 68)
                numpadButton(0)
                DeleteButton(size: buttonSize)
            }
        }
    }

    private func numpadButton(_ number: Int) -> NumpadButton {
        NumpadButton(number: number, size: buttonSize) {
            didChooseNumber?(number)
        }
    }
}

struct NumpadView_Previews: PreviewProvider {
    static var previews: some View {
        NumpadView()
    }
}
