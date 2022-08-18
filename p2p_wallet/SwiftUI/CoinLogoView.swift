import Combine
import SkeletonUI
import SwiftSVG
import SwiftUI

struct CoinLogoView: View {
    var image: UIImage?
    var imageURL: URL?

    var body: some View {
        if let imageURL = self.imageURL {
            ImageView(
                withURL: imageURL
            )
        } else if let image = self.image {
            Image(uiImage: image)
        }
    }
}

struct ImageView: View {
    @ObservedObject var imageLoader: ImageLoader
    @State var image: UIImage? = .init()
    @State var svg: Data = .init()
    @State var isLoading = true

    init(withURL url: URL) {
        imageLoader = ImageLoader(url: url)
    }

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity($svg.isEmpty ? 1 : 0)
                .skeleton(with: isLoading)
            SVGView(svg: $svg)
                .opacity($svg.isEmpty ? 0 : 1)
                .frame(width: 48, height: 48)
        }.onReceive(imageLoader.didChange) { data in
            if let image = UIImage(data: data) {
                self.image = image
            } else {
                self.svg = data
            }
            self.isLoading = false
        }
    }
}

/// UIView to show svgs
struct SVGView: UIViewRepresentable {
    func updateUIView(_ uiView: UIView, context _: Context) {
        CALayer(SVGData: svg) { layer in
            uiView.layer.sublayers?.removeAll()
            layer.resizeToFit(uiView.bounds)
            uiView.layer.addSublayer(layer)
        }
    }

    typealias UIViewType = UIView
    @Binding var svg: Data

    func makeUIView(context _: Context) -> UIView {
        UIView(SVGData: svg)
    }

    static func dismantleUIView(_: UIViewType, coordinator _: Coordinator<Any>) {}

    func makeCoordinator() -> SVGViewCoordinator<Data> {
        SVGViewCoordinator(data: $svg)
    }
}

class SVGViewCoordinator<T>: NSObject {
    @Binding private var data: T

    init(data: Binding<T>) {
        _data = data
    }
}

/// Loader to get retreive images
class ImageLoader: ObservableObject {
    var didChange = PassthroughSubject<Data, Never>()
    var data = Data() {
        didSet {
            didChange.send(data)
        }
    }

    init(url: URL) {
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async {
                self.data = data
            }
        }
        task.resume()
    }
}
