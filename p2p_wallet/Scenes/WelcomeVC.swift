//
//  WelcomeVC.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/23/20.
//

import Foundation

class WelcomeVC: BaseVC {
    let numberOfPages = 2
    
    // MARK: - Properties
    lazy var pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    var currentPage = 0
    
    // MARK: - Subviews
    lazy var stackView = UIStackView(axis: .vertical, spacing: 31, alignment: .center, distribution: .fill)
    
    lazy var pageControl: UIPageControl = {
        let pc = UIPageControl(forAutoLayout: ())
        pc.numberOfPages = numberOfPages
        return pc
    }()
    
    override func setUp() {
        super.setUp()
        
        let imageView = UIImageView(width: 220, height: 220, cornerRadius: 110)
        imageView.image = .walletIntro
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(UILabel(text: L10n.wowletForPeopleNotForTokens, textSize: 32, weight: .bold, numberOfLines: 0, textAlignment: .center))
        
        // FIXME: - Change text
        stackView.addArrangedSubview(UILabel(text: "For athletes, high altitude produces two contradictory effects on performance. For explosive events (sprints up to 400 metres, long jump, triple jump) the reduction in atmospheric pressure means there is", textSize: 17, weight: .medium, textColor: UIColor.appBlack.withAlphaComponent(0.6), numberOfLines: 0, textAlignment: .center))
        
        view.addSubview(stackView)
        stackView.autoCenterInSuperview()
        stackView.autoPinEdge(toSuperviewEdge: .leading, withInset: 30)
        stackView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 30)
        
        view.addSubview(pageControl)
        pageControl.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 30)
        pageControl.autoAlignAxis(toSuperviewAxis: .vertical)
        
        pageControl.pageIndicatorTintColor = .a4a4a4
        pageControl.currentPageIndicatorTintColor = .black
    }
    
    override func injected() {
        stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
        super.injected()
    }
}
