import SwiftUI

struct _NumpadView: View {

    // MARK: - Constants

    private let buttonSize: CGFloat = 68
    private let spacing: CGFloat = 42
    private let vSpacing: CGFloat = 12

    // MARK: - Properties

    @State private var deleteButtonColor = Color(UIColor(red: 0, green: 0, blue: 0, alpha: 1))
    
    var didChooseNumber: ((Int) -> Void)?
    var didTapDelete: (() -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(spacing: vSpacing) {
            ForEach(1...3, id: \.self) { number in
                _NumpadButton(number: number)
            }
            ForEach(4...6, id: \.self) { number in
                _NumpadButton(number: number)
            }
            ForEach(7...9, id: \.self) { number in
                _NumpadButton(number: number)
            }
            HStack(spacing: spacing) {
                _NumpadButton(number: 0)
                deleteButton
            }
        }
    }

    // MARK: - ViewBuilder

    private var deleteButton: some View {
        Image(systemName: "xmark")
            .resizable()
            .frame(width: buttonSize, height: buttonSize)
            .foregroundColor(deleteButtonColor)
            .onLongPressGesture(minimumDuration: 0, pressing: { isPressing in
                deleteButtonColor = isPressing ? deleteButtonColor.opacity(0.65) : deleteButtonColor
            },perform: didTapDeleteButton)
    }

    // MARK: - Helpers
    private func didTapDeleteButton() {
        didTapDelete?()
        deleteButtonColor = Color(UIColor(red: 0, green: 0, blue: 0, alpha: 1))
    }
}

private extension View {
    @discardableResult
    func onLongTap(_ target: Any?, action: Selector, minimumPressDuration: TimeInterval) -> some View {
        self.onLongPressGesture(minimumDuration: minimumPressDuration, perform: { })
    }
}
