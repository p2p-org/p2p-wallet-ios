//
//  ProfileSingleSelectionVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/01/2021.
//

import Foundation

class ProfileSingleSelectionVC<T: Hashable>: ProfileVCBase {
    var data: [T: Bool] = [T: Bool]()
    var cells: [Cell<T>] {stackView.arrangedSubviews.filter {$0 is Cell<T>} as! [Cell<T>]}
    var selectedItem: T {data.first(where: {$0.value})!.key}
    
    override func setUp() {
        super.setUp()
        // views
        stackView.addArrangedSubviews(data.keys.sorted(by: {(data[$0] ?? data[$1] ?? false)}).map {self.createCell(item: $0)})
        
        // reload
        reloadData()
    }
    
    func reloadData() {
        for cell in cells {
            guard let item = cell.item else {continue}
            cell.checkBox.isSelected = data[item] ?? false
        }
    }
    
    func createCell(item: T) -> Cell<T> {
        let cell = Cell<T>(height: 66)
        cell.item = item
        cell.onTap(self, action: #selector(rowDidSelect(_:)))
        return cell
    }
    
    @objc func rowDidSelect(_ gesture: UIGestureRecognizer) {
        guard let cell = gesture.view as? Cell<T>,
              let item = cell.item,
              let isCellSelected = data[item],
              isCellSelected == false
        else {return}
        
        data[item] = true
        
        // deselect all other networks
        data.keys.filter {$0 != item}.forEach {data[$0] = false}
        
        reloadData()
    }
}

extension ProfileSingleSelectionVC {
    class Cell<T>: BEView {
        var item: T?
        
        lazy var label = UILabel(text: nil)
        
        lazy var checkBox: BECheckbox = {
            let checkBox = BECheckbox(width: 20, height: 20, cornerRadius: 10)
            checkBox.isUserInteractionEnabled = false
            return checkBox
        }()
        
        override func commonInit() {
            super.commonInit()
            backgroundColor = .textWhite
            self.row([label, checkBox])
        }
    }
}
