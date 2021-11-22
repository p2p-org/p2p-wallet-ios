//
//  WLOverviewView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/12/2020.
//

import Foundation
import UIKit
import BEPureLayout

class WLOverviewView: BERoundedCornerShadowView {
    // MARK: - Initializer
    init() {
        super.init(shadowColor: UIColor.black.withAlphaComponent(0.05), radius: 8, offset: CGSize(width: 0, height: 1), opacity: 1, cornerRadius: 8)
        self.border(width: 1, color: .f2f2f7.onDarkMode(.white.withAlphaComponent(0.1)))
    }
    
    override func commonInit() {
        super.commonInit()
        layer.cornerRadius = 12
        layer.masksToBounds = true
        backgroundColor = .grayMain
        
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        
        stackView.addArrangedSubviews {
            createTopView()
            UIView.separator(height: 1, color: .separator)
            createButtonsView()
        }
    }
    
    func createTopView() -> UIView {
        fatalError("Must override")
    }
    
    func createButtonsView() -> UIView {
        fatalError("Must override")
    }
    
    func createButton(image: UIImage, title: String) -> UIView {
        let view = UIView(forAutoLayout: ())
        
        let stackView = UIStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill)
            {
                UIImageView(width: 24, height: 24, image: image, tintColor: .h5887ff)
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
