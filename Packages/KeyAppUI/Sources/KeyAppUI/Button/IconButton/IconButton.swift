// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import Foundation
import PureLayout
import UIKit

/// Button with focus on icon. Title is secondary
public class IconButton: ButtonControl<IconButtonAppearance> {
    /// On pressed callback
    let imageContainer = BERef<UIView>()
    let imageView = BERef<UIImageView>()
    let titleSpacing = BERef<UIView>()
    let titleView = BERef<UILabel>()

    public var image: UIImage {
        didSet {
            imageView.image = image
        }
    }

    public var title: String? {
        didSet {
            titleView.text = title
            titleView.isHidden = title == nil
        }
    }

    public init(image: UIImage, title: String? = nil, themes: ThemeState<IconButtonAppearance> = [:]) {
        self.image = image
        self.title = title

        var themes = themes
        if themes[.normal] == nil {
            themes[.normal] = .default()
            themes[.highlighted] = .default().copy(backgroundColor: .gray)
        }

        super.init(frame: .zero, themes: themes)
    }

    override func build() -> UIView {
        BEVStack(alignment: .center) {
            BEContainer {
                BECenter {
                    UIImageView(image: image, contentMode: .scaleAspectFill)
                        .frame(width: theme.iconSize, height: theme.iconSize)
                        .bind(imageView)
                }
            }
            .autoAdjustWidthHeightRatio(1)
            .box(cornerRadius: theme.borderRadius)
            .bind(imageContainer)
            .withTag(1)

            UIView()
                .frame(height: theme.titleSpacing)
                .bind(titleSpacing)
            UILabel(text: title)
                .bind(titleView)
        }.setup { view in
            guard let imageContainer = view.viewWithTag(1) else { return }
            let widthConstraint: NSLayoutConstraint = imageContainer.autoMatch(.width, to: .width, of: view, withMultiplier: 1.0, relation: .equal)
            widthConstraint.priority = .defaultLow
        }
    }

    override func update(animated: Bool) {
        titleView.textColor = theme.titleColor
        titleView.font = theme.font

        imageView.tintColor = theme.iconColor
        imageView.view?.widthConstraint?.constant = theme.iconSize
        imageView.view?.heightConstraint?.constant = theme.iconSize

        imageContainer.view?.layer.cornerRadius = theme.borderRadius
        if let color = theme.borderColor {
            imageContainer.view?.layer.borderWidth = 2
            imageContainer.view?.layer.borderColor = color.cgColor
        }

        titleSpacing.view?.heightConstraint?.constant = theme.titleSpacing

        super.update(animated: animated)
    }

    override func updateAnimated() {
        imageContainer.backgroundColor = theme.backgroundColor
        super.updateAnimated()
    }
}
