//
//  ActivityIndicator.swift
//  p2p_wallet
//
//  Created by Ivan on 02.08.2022.
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
    typealias UIView = UIActivityIndicatorView
    var isAnimating: Bool = true
    var configuration = { (_: UIView) in }

    init(isAnimating: Bool, configuration: ((UIView) -> Void)? = nil) {
        self.isAnimating = isAnimating
        if let configuration = configuration {
            self.configuration = configuration
        }
    }

    func makeUIView(context _: UIViewRepresentableContext<Self>) -> UIView {
        UIView()
    }

    func updateUIView(_ uiView: UIView, context _: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        configuration(uiView)
    }
}
