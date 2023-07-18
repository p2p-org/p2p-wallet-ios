import SwiftUI

private struct DelaysTouchesButtonStyle: ButtonStyle {
    @Binding var disabled: Bool
    var duration: TimeInterval
    @Binding var touchDownDate: Date?
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed, perform: handleIsPressed)
    }
    
    private func handleIsPressed(isPressed: Bool) {
        if isPressed {
            let date = Date()
            touchDownDate = date
            
            DispatchQueue.main.asyncAfter(deadline: .now() + max(duration, 0)) {
                if date == touchDownDate {
                    disabled = true
                    
                    DispatchQueue.main.async {
                        disabled = false
                    }
                }
            }
        } else {
            touchDownDate = nil
            disabled = false
        }
    }
}
