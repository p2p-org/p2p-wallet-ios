//
//  PincodeViewController.swift
//  KeyAppUIExample
//
//  Created by Giang Long Tran on 27.07.2022.
//

import BEPureLayout
import Foundation
import KeyAppUI
import UIKit

class PincodeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Asset.Colors.lime.color

        navigationItem.title = "Step 2 of 3"
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: Asset.Colors.night.color]

        // Left button
        let backButton = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(onBack)
        )
        backButton.tintColor = Asset.Colors.night.color

        let spacing = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacing.width = 8

        navigationItem.setLeftBarButtonItems([spacing, backButton], animated: false)

        // Right button
        let infoButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        infoButton.addTarget(self, action: #selector(onInfo), for: .touchUpInside)
        infoButton.setImage(Asset.MaterialIcon.helpOutline.image, for: .normal)
        infoButton.contentMode = .scaleAspectFill
        infoButton.tintColor = Asset.Colors.night.color
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)

        // Pincode
        let child = BESafeArea {
            BEVStack {
                UIView.spacer
                UILabel(text: "Confirm your PIN code", font: .font(of: .title2, weight: .regular),textAlignment: .center)
                PinCode(correctPincode: "123456")
                    .setup { pincode in
                        pincode.resetingDelayInSeconds = 2
                    }
                UIView(height: 70)
            }
        }
        view.addSubview(child)
        child.autoPinEdgesToSuperviewEdges()
    }

    @objc func onBack() {
        dismiss(animated: true)
    }

    @objc func onInfo() {
        dismiss(animated: true)
    }
}
