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
                ForEach(1...3, id: \.self) { number in
                    NumpadButton(number: number, size: buttonSize)
                }
            }
            
            HStack(spacing: spacing) {
                ForEach(4...6, id: \.self) { number in
                    NumpadButton(number: number, size: buttonSize)
                }
            }
            
            HStack(spacing: spacing) {
                ForEach(7...9, id: \.self) { number in
                    NumpadButton(number: number, size: buttonSize)
                }
            }
            HStack(spacing: spacing) {
                Spacer().frame(width: 68, height: 68)
                NumpadButton(number: 0, size: buttonSize)
                DeleteButton(size: buttonSize)
            }
        }
    }
}

struct NumpadView_Previews: PreviewProvider {
    static var previews: some View {
        NumpadView()
    }
}
