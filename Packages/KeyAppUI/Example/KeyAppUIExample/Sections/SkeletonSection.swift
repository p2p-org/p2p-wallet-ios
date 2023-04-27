import BEPureLayout
import KeyAppUI

class SkeletonSection: BECompositionView {
    override func build() -> UIView {
        BEVStack {
            UILabel(text: "Skeletons", textSize: 22).padding(.init(only: .top, inset: 20))
            BEVStack(spacing: 10) {
                BEHStack(spacing: 10, alignment: .center, distribution: .fill) {
                    UIImageView(width: 60, height: 60)
                    BEVStack(spacing: 20) {
                        UILabel(text: "")
                        UILabel(text: "")
                        UILabel(text: "")
                    }
                }.padding(.init(only: .bottom, inset: 15))
                BEVStack(spacing: 7) {
                    UILabel(text: "1")
                    UILabel(text: "2")
                }.padding(.init(only: .bottom, inset: 15))
                BEHStack(spacing: 10) {
                    UIImageView(width: 100, height: 100)
                    UIImageView(width: 100, height: 100)
                    UIImageView(width: 100, height: 100)
                    BESpacer(.horizontal)
                }
            }.setup { stack in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    stack.showDefaultAnimatedSkeleton()
                }
            }
        }
    }
}
