// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import Foundation
import UIKit

public class ButtonControl<T>: UIControl {
    public typealias ThemeState<T> = [State: T]
    
    var onPressed: BECallback<ButtonControl<T>>?

    var themes: ThemeState<T> = [:] {
        didSet { update() }
    }

    /// Animation configuration
    let propertiesAnimator = UIViewPropertyAnimator(duration: 0.12, curve: .easeInOut)

    init(frame: CGRect, themes: ThemeState<T>) {
        self.themes = themes
        super.init(frame: frame)

        // Build
        let child = build()
        addSubview(child)
        child.autoPinEdgesToSuperviewEdges()

        // Update
        update(animated: false)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func build() -> UIView {
        fatalError("Build is not implemented")
    }

    /// Current theme base on button state
    var theme: T {
        var theme: T?
        if state.contains(.disabled) {
            theme = themes[.disabled]
        } else if state.contains(.highlighted) {
            theme = themes[.highlighted]
        }
        return theme ?? themes[.normal]!
    }

    func update(animated: Bool = true) {
        propertiesAnimator.stopAnimation(true)
        if animated {
            propertiesAnimator.addAnimations { [weak self] in self?.updateAnimated() }
            propertiesAnimator.startAnimation()
        } else {
            updateAnimated()
        }
    }

    /// Applying part with animation
    func updateAnimated() {}

    // MARK: Touches handler

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if onPressed != nil || state.contains(.disabled) { isHighlighted = true }
        update()

        super.touchesBegan(touches, with: event)
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: superview) else { return }
        isHighlighted = false

        if frame.contains(location) {
            if !state.contains(.disabled) { onPressed?(self) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in self?.update() }
        } else {
            update()
        }

        super.touchesEnded(touches, with: event)
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = false
        update()
        super.touchesCancelled(touches, with: event)
    }

    @discardableResult
    public func onPressed(_ callback: BECallback<ButtonControl<T>>?) -> Self {
        onPressed = callback
        return self
    }

    override public var isEnabled: Bool {
        get { super.isEnabled }
        set {
            super.isEnabled = newValue
            update()
        }
    }
}

extension UIControl.State: Hashable {}
