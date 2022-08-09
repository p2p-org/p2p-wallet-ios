//
//  RefreshableScrollView.swift
//  p2p_wallet
//
//  Created by Ivan on 02.08.2022.
//

import SwiftUI
import UIKit

struct RefreshableScrollView<Content: View>: UIViewRepresentable {
    public typealias Action = () -> Void
    @Binding var refreshing: Bool
    @Binding var onTop: Bool
    let action: Action?
    let content: () -> Content

    init(
        refreshing: Binding<Bool>,
        onTop: Binding<Bool> = .constant(true),
        action: Action? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.action = action
        self.content = content
        _refreshing = refreshing
        _onTop = onTop
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.refreshControl = UIRefreshControl()
        scrollView.refreshControl?.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleRefreshControl),
            for: .valueChanged
        )
        updateView(scrollView: scrollView)
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context _: Context) {
        if !refreshing, uiView.refreshControl?.isRefreshing == true {
            uiView.refreshControl?.endRefreshing()
        }
        if onTop {
            uiView.scrollTo(y: 0, animated: false)
        }
        updateView(scrollView: uiView)
    }

    private func updateView(scrollView: UIScrollView) {
        scrollView.subviews.forEach {
            if !($0 is UIRefreshControl) {
                $0.removeFromSuperview()
            }
        }

        let content = content().uiView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        let constraints = [
            content.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ]
        scrollView.addConstraints(constraints)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        let control: RefreshableScrollView

        init(_ control: RefreshableScrollView) {
            self.control = control
        }

        @objc func handleRefreshControl(sender _: UIRefreshControl) {
            control.action?()
            control.refreshing = true
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            control.onTop = scrollView.contentOffset == .zero
        }
    }
}
