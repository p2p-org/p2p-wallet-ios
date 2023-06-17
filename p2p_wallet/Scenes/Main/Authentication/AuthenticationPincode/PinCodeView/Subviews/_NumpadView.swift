import SwiftUI

struct _NumpadView: View {
    private let buttonSize: CGFloat = 68
    private let spacing: CGFloat = 42
    private let vSpacing: CGFloat = 12
    
    @State private var deleteButtonColor = Color(UIColor(red: 0, green: 0, blue: 0, alpha: 1))
    
    var didChooseNumber: ((Int) -> Void)?
    var didTapDelete: (() -> Void)?
    
    private var numButtons: [NumpadButton] {
        var views = [NumpadButton]()
        for index in 0 ..< 10 {
            let view = NumpadButton(width: buttonSize, height: buttonSize, cornerRadius: 20)
            view.label.text = "\(index)"
            view.tag = index
            view.onLongTap(self, action: #selector(numButtonDidTap(_:)), minimumPressDuration: 0)
            views.append(view)
        }
        return views
    }
    
    private var deleteButton: some View {
        Image(systemName: "xmark")
            .resizable()
            .frame(width: buttonSize, height: buttonSize)
            .foregroundColor(deleteButtonColor)
            .onLongPressGesture(minimumDuration: 0, pressing: { isPressing in
                deleteButtonColor = isPressing ? deleteButtonColor.opacity(0.65) : deleteButtonColor
            }, perform: didTapDeleteButton)
    }
    
    var body: some View {
        VStack(spacing: vSpacing) {
            buttons(from: 1, to: 3)
            buttons(from: 4, to: 6)
            buttons(from: 7, to: 9)
            HStack(spacing: spacing) {
                numButtons[0]
                deleteButton
            }
        }
    }
    
    private func buttons(from: Int, to: Int) -> some View {
        HStack(spacing: spacing) {
            ForEach(from...to, id: \.self) { index in
                numButtons[index]
            }
        }
    }
    
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
