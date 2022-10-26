import SwiftUI
import Lottie
 
struct LottieView: UIViewRepresentable {
    let lottieFile: String
    let loopMode: LottieLoopMode
    let contentMode: UIView.ContentMode
    let completion: (() -> Void)?
 
    private let animationView = LottieAnimationView()
    
    init(lottieFile: String, loopMode: LottieLoopMode, contentMode: UIView.ContentMode = .scaleAspectFit, completion: (() -> Void)? = nil) {
        self.lottieFile = lottieFile
        self.loopMode = loopMode
        self.contentMode = contentMode
        self.completion = completion
    }
 
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
 
        animationView.animation = Animation.named(lottieFile)
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode
        animationView.play { _ in completion?() }
 
        view.addSubview(animationView)
 
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        animationView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
 
        return view
    }
 
    func updateUIView(_ uiView: UIViewType, context: Context) {
 
    }
}
