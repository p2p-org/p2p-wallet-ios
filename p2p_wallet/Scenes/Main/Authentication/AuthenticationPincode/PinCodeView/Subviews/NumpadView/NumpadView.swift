import SwiftUI
import KeyAppUI

struct NumpadView: View {

    // MARK: - Constants

    private let buttonSize: CGFloat = 68
    private let spacing: CGFloat = 42
    private let vSpacing: CGFloat = 12

    // MARK: - Properties

    @State private var deleteButtonColor = Color(Asset.Colors.night.color)
    
    let showBiometry: Bool
    let isDeleteButtonHidden: Bool
    var didChooseNumber: ((Int) -> Void)?
    var didTapDelete: (() -> Void)?
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
                    didTapDelete?()
                }
                    .opacity(isDeleteButtonHidden ? 0: 1)
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
        NumpadView(showBiometry: true, isDeleteButtonHidden: false)
    }
}
