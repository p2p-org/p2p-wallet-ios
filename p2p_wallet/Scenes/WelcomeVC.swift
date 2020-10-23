//
//  WelcomeVC.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/23/20.
//

import Foundation

class WelcomeVC: BaseVC {
    let numberOfPages = 3
    
    // MARK: - Properties
    lazy var pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    var currentPage = 0
    
    // MARK: - Subviews
}
