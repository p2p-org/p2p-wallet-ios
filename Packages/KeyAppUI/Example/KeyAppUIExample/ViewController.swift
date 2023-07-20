//
//  ViewController.swift
//  KeyAppUIExample
//
//  Created by Ivan on 09.06.2022.
//

import Algorithms
import BEPureLayout
import KeyAppUI
import UIKit

class ViewController: UIViewController {
    @IBOutlet var stackView: UIStackView!
    let splashRef = BERef<SplashView>()
    let sliderRef = BERef<UISlider>()
    let sliderButton = BERef<SliderButton>()

    override func viewDidLoad() {
        super.viewDidLoad()

        let child = build()
        view.addSubview(child)
        child.autoPinEdgesToSuperviewEdges()

        view.backgroundColor = UIColor(red: 0.91, green: 0.92, blue: 0.95, alpha: 1)

        addSplash()
        sliderRef.view?.addTarget(self, action: #selector(sliderValueDidChange(_:)), for: .valueChanged)
        let progress = CGFloat.random(in: 0...1)
        splashRef.progress = progress
        sliderRef.view?.value = Float(progress)
    }

    func build() -> UIView {
        BEScrollView(contentInsets: .init(all: 16)) {
            BEVStack {
                SliderButton(
                    image: Asset.MaterialIcon.appleLogo.image,
                    title: "Change Apple ID", style: .solidBlack
                )
                .bind(sliderButton)

                BEHStack(spacing: 10, alignment: .center) {
                    UISlider(width: 100)
                        .setup {slider in
                            slider.minimumValue = 0
                            slider.maximumValue = 1.0
                        }
                        .bind(sliderRef)
                    
                    SplashView()
                        .bind(splashRef)
                        .padding(.init(x: 0, y: 10))
                        .centered(.horizontal)
                    
                    
                }
                
                
                TextButton(title: "Show pincode view controller", style: .invertedRed, size: .large)
                    .onPressed { [weak self] _ in
                        self?.performSegue(withIdentifier: "showPincode", sender: nil)
                    }
    
                TextFieldSection()
                
                SkeletonSection()
                
                SplashSection().onTap { [weak self] in
                    self?.presentSplash()
                }

                TipSection()
                    .onTap { [weak self] in
                        self?.performSegue(withIdentifier: "showTipExample", sender: nil)
                    }

                SliderSection()
                
                CircularProgressIndicatorSection()

                TableSection().onTap { [weak self] in
                    self?.present(TableViewController(), animated: true)
                }

                SnackBarSection()

                IconSection()

                TypographySection()

                // Buttons
                TextButtonSection()
                IconButtonSection()
            }
        }
        .setup { view in view.scrollView.keyboardDismissMode = .onDrag }
    }

    private func presentSplash() {
        let splashVC = SplashViewController()
        present(splashVC, animated: true)
    }

    private func addSplash() {
        let child = SplashViewController()
        child.stop { [weak self, weak child] in
            guard let self = self, let child = child else { return }
            self.removeSplash(child)
        }

        addChild(child)

        view.addSubview(child.view)
        child.view.autoPinEdgesToSuperviewEdges()
        child.didMove(toParent: self)
    }

    private func removeSplash(_ vc: SplashViewController) {
        vc.willMove(toParent: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParent()
    }
    
    @objc func sliderValueDidChange(_ sender:UISlider!)
    {
        splashRef.progress = CGFloat(sender.value)
    }
}
