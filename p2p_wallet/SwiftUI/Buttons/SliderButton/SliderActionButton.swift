import KeyAppUI
import SwiftUI

struct SliderActionButtonData {
    let isEnabled: Bool
    let title: String
    static let zero = SliderActionButtonData(isEnabled: false, title: L10n.enterAmount)
}

struct SliderActionButton: View {
    @State private var animatedFinish: Bool = false
    
    @Binding var isSliderOn: Bool
    
    let data: SliderActionButtonData
    let showFinished: Bool

    init(
        isSliderOn: Binding<Bool>,
        data: SliderActionButtonData,
        showFinished: Bool
    ) {
        _isSliderOn = isSliderOn
        self.data = data
        self.showFinished = showFinished
    }

    var body: some View {
        Group {
            if animatedFinish {
                Circle()
                    .stroke(Color(Asset.Colors.night.color), lineWidth: 4)
                    .background(Circle().fill(Color(Asset.Colors.lime.color)))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(uiImage: .check)
                            .renderingMode(.template)
                            .foregroundColor(Color(Asset.Colors.night.color))
                    )
            } else {
                if data.isEnabled {
                    SliderButtonView(
                        title: data.title,
                        image: .arrowRight,
                        style: .solidBlack,
                        isOn: Binding(get: {
                            self.isSliderOn
                        }, set: { val in
                            withAnimation { self.isSliderOn = val }
                        })
                    )
                } else {
                    NewTextButton(title: data.title, style: .primary, isEnabled: false, action: { })
                        .cornerRadius(radius: 32, corners: .allCorners)
                }
            }
        }
        .frame(height: TextButton.Size.large.height)
        .disabled(!data.isEnabled)
        .allowsHitTesting(data.isEnabled)
        .transition(.asymmetric(insertion: .scale, removal: .scale).combined(with: .opacity))
        .animation(.default, value: animatedFinish)
        .padding(.top, 8)
        .onChange(of: showFinished, perform: { newValue in
            withAnimation {
                self.animatedFinish = newValue
            }
        })
    }
}
