//
//  BEBuilder.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/08/2022.
//

import Combine
import Foundation

class BEBuilder<T>: UIView {
    typealias Build<T> = (T) -> UIView
    private let build: Build<T>
    private var subscriptions = [AnyCancellable]()
    private var child: UIView?
    init(publisher: AnyPublisher<T, Never>, build: @escaping Build<T>) {
        self.build = build
        super.init(frame: .zero)

        publisher
            .sink { [weak self] value in
                guard let self = self else { return }
                self.child?.alpha = 0.0
                let view = self.build(value)
                self.addSubview(view)

                self.child?.removeFromSuperview()
                self.child = view
            }
            .store(in: &subscriptions)
    }

    override func addSubview(_ view: UIView) {
        super.addSubview(view)
        view.autoPinEdgesToSuperviewEdges()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("Loading this view from a nib is unsupported in favor of initializer dependency injection.")
    }
}
