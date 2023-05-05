import BEPureLayout
import KeyAppUI
import UIKit

final class SliderSection: BECompositionView {

    private let blackSlider = BERef<Slider>()
    private let whiteSlider = BERef<Slider>()

    private var timer: Timer?

    override init() {
        super.init()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self = self, self.blackSlider.view != nil, self.whiteSlider.view != nil else { return }
            self.blackSlider.view?.prevDot()
            self.whiteSlider.view?.nextDot()
        }
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    override func build() -> UIView {
        BEVStack(spacing: 20) {
            UILabel(text: "Slider", textSize: 22)
                .padding(.init(only: .top, inset: 20))

            BEHStack(spacing: 16) {
                Slider(count: 4)
                    .setup { slider in
                        slider.tintColor = UIColor.black
                    }
                    .bind(blackSlider)
                Slider(count: 5)
                    .setup { slider in
                        slider.tintColor = UIColor.white
                    }
                    .bind(whiteSlider)
                UIView.spacer
            }
        }
    }
    
    
}
