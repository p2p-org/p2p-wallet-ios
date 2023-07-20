// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import Foundation
import KeyAppUI

class IconButtonSection: BECompositionView {
    override func build() -> UIView {
        BEVStack {
            UILabel(text: "Icon buttons", textSize: 22).padding(.init(top: 20, left: 0, bottom: 10, right: 0))
            BEVStack(spacing: 8, alignment: .fill) {
                UILabel(text: "With text", textSize: 22).padding(.init(top: 20, left: 0, bottom: 10, right: 0))
                iconButton()

                UILabel(text: "Without text", textSize: 22).padding(.init(top: 20, left: 0, bottom: 10, right: 0))
                iconButton()
            }
        }
    }

    private func iconButton() -> UIView {
        BEVStack(spacing: 8) {
            for style in IconButton.Style.allCases {
                BEHStack(spacing: 8, alignment: .center, distribution: .fill) {
                    for size in IconButton.Size.allCases {
                        IconButton(
                            image: Asset.MaterialIcon.appleLogo.image,
                            title: "\(style)",
                            style: style,
                            size: size
                        )
                        .onPressed { [weak self] _ in
                            self?.shareCodeTemplate(style: style, size: size)
                        }
                    }
                    UIView.spacer
                }
            }
            
            for style in IconButton.Style.allCases {
                BEHStack(spacing: 8, alignment: .center, distribution: .fill) {
                    for size in IconButton.Size.allCases {
                        IconButton(
                            image: Asset.MaterialIcon.appleLogo.image,
                            title: "\(style)",
                            style: style,
                            size: size
                        )
                        .onPressed { [weak self] _ in
                            self?.shareCodeTemplate(style: style, size: size)
                        }
                    }
                    UIView.spacer
                }.setup { button in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        button.makeSkeletonable()
                        button.showSkeleton()

                    }
                }
            }
        }
    }

    func shareCodeTemplate(style: IconButton.Style, size: IconButton.Size) {
        CodeTemplate.share(code:
            """
            IconButton(
                image: Asset.MaterialIcon.<#name#>.image,
                title: <#T##String#>,
                style: .\(style),
                size: .\(size)
            )
            .onPressed { <#code#> }
            """
        )
    }
}
