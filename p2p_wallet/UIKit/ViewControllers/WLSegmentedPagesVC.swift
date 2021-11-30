//
//  WLSegmentedPagesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import BEPureLayout

class WLSegmentedPagesVC: BEPagesVC {
    struct Item {
        let label: String
        let viewController: UIViewController
    }
    
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    
    // MARK: - Properties
    private let segmentedItems: [String]
    
    // MARK: - Subviews
    private lazy var stackView = UIStackView(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fill)
    
    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: segmentedItems)
        control.addTarget(self, action: #selector(segmentedValueChanged(_:)), for: .valueChanged)
        control.autoSetDimension(.width, toSize: 339, relation: .greaterThanOrEqual)
        return control
    }()
    
    // MARK: - Initializers
    init(items: [Item]) {
        self.segmentedItems = items.map {$0.label}
        super.init()
        self.viewControllers = items.map {$0.viewController}
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .background
        
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .zero)
        
        stackView.insertArrangedSubview(segmentedControl.centered(.horizontal), at: 0)
        
        // action
        currentPage = -1
        moveToPage(0)
        
        segmentedControl.selectedSegmentIndex = 0
    }
    
    override func setUpContainerView() {
        stackView.addArrangedSubview(containerView)
    }
    
    override func setUpPageControl() {
        // do nothing
    }
    
    override func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        super.pageViewController(pageViewController, didFinishAnimating: finished, previousViewControllers: previousViewControllers, transitionCompleted: completed)
        if let vc = pageVC.viewControllers?.first,
           let index = viewControllers.firstIndex(of: vc),
           segmentedControl.selectedSegmentIndex != index
        {
            segmentedControl.selectedSegmentIndex = index
        }
    }
    
    // MARK: - Actions
    @objc func segmentedValueChanged(_ sender: UISegmentedControl!) {
        moveToPage(sender.selectedSegmentIndex)
    }
    
    func hideSegmentedControl() {
        segmentedControl.superview?.isHidden = true
    }
    
    func disableScrolling() {
        for view in pageVC.view.subviews where view is UIScrollView {
            (view as! UIScrollView).isScrollEnabled = false
        }
    }
}
