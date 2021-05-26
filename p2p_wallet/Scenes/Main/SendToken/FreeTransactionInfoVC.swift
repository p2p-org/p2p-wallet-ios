//
//  FreeTransactionInfoVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/05/2021.
//

import Foundation

class FreeTransactionInfoVC: FlexibleHeightVC {
    override var padding: UIEdgeInsets {.init(x: 20, y: 30)}
    
    override func setUp() {
        super.setUp()
        stackView.spacing = 30
        stackView.addArrangedSubviews {
            UIView(forAutoLayout: ())
                .withModifier { view in
                    let separator = UIView.separator(height: 1, color: .separator)
                    view.addSubview(separator)
                    separator.autoAlignAxis(toSuperviewAxis: .horizontal)
                    separator.autoPinEdge(toSuperviewEdge: .leading)
                    separator.autoPinEdge(toSuperviewEdge: .trailing)
                    let presentImageView = UIImageView(width: 45, height: 45, image: .present)
                        .padding(.init(all: 10), backgroundColor: .h5887ff, cornerRadius: 12)
                    view.addSubview(presentImageView)
                    presentImageView.autoPinEdge(toSuperviewEdge: .top)
                    presentImageView.autoPinEdge(toSuperviewEdge: .bottom)
                    presentImageView.autoAlignAxis(toSuperviewAxis: .vertical)
                    return view
                }
            
            UILabel(text: L10n.WillBePaidByP2p.orgWeTakeCareOfAllTransfersCosts, textSize: 15, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
            
            WLButton.stepButton(type: .blue, label: L10n.great)
                .onTap(self, action: #selector(back))
        }
    }
    
    override func fittingHeightInContainer(frame: CGRect) -> CGFloat {
        let height = super.fittingHeightInContainer(frame: frame)
        return height + 30
    }
    
    override func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = super.presentationController(forPresented: presented, presenting: presenting, source: source) as! PresentationController
        pc.roundedCorner = [.topLeft, .topRight]
        pc.cornerRadius = 25
        return pc
    }
}
