//
//  WLOverviewView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/12/2020.
//

import Foundation
import UIKit

class WLOverviewView: WLFloatingPanelView {
    override func commonInit() {
        super.commonInit()
        stackView.spacing = 0
        backgroundColor = .grayMain

        let buttonsView = createButtonsView()
        stackView.addArrangedSubviews {
            createTopView()
            UIView.separator(height: 1, color: .separator)
            buttonsView
        }

        buttonsView.autoMatch(.height, to: .height, of: self, withMultiplier: 1.0, relation: .lessThanOrEqual)
    }
    
    func createTopView() -> UIView {
        fatalError("Must override")
    }
    
    func createButtonsView() -> UIView {
        fatalError("Must override")
    }
    
    func createButton(title: String) -> UIView {
        let view = UIView(forAutoLayout: ())
        
        let stackView = UIStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill)
            {
                // UIImageView(width: 24, height: 24, image: image, tintColor: .h5887ff)
                UILabel(text: title, textSize: 15, weight: .medium, textColor: .h5887ff)
            }
        
        view.addSubview(stackView)
        stackView.autoAlignAxis(toSuperviewAxis: .vertical)
        stackView.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
        stackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18)
        return view
    }
    
    func showLoading() {
        stackView.arrangedSubviews.forEach {$0.hideLoader()}
        stackView.arrangedSubviews.forEach {$0.showLoader(customGradientColor: .defaultLoaderGradientColors)}
    }

    func hideLoading() {
        stackView.arrangedSubviews.forEach {$0.hideLoader()}
    }
}
