//
// Created by Giang Long Tran on 15.02.2022.
//

import UIKit
import RxSwift

extension Home {
    class EmptyView: BECompositionView {
        private let disposeBag = DisposeBag()
        private let viewModel: HomeViewModelType
        let refreshControl = UIRefreshControl()
        
        init(viewModel: HomeViewModelType) {
            self.viewModel = viewModel
            super.init()
            
            refreshControl.addTarget(self, action: #selector(reload), for: .valueChanged)
            viewModel
                .walletsRepository
                .stateObservable
                .subscribe(onNext: { [weak self] state in
                    if state == .loaded { self?.refreshControl.endRefreshing() }
                })
                .disposed(by: disposeBag)
        }
        
        override func build() -> UIView {
            BEScrollView(alwaysBounceVertical: true, refreshControl: refreshControl) {
                BEVStack {
                    // Logo
                    BEZStack {
                        BEZStackPosition(mode: .center) {
                            CircleGradientView()
                                .frame(width: 443, height: 433)
                        }
                        BEZStackPosition(mode: .center) {
                            UIView(
                                width: 140,
                                height: 140,
                                backgroundColor: UIColor(red: 0.783, green: 0.883, blue: 1, alpha: 1)
                            ).box(cornerRadius: 40)
                        }
                        BEZStackPosition(mode: .fill) {
                            UIImageView(width: 263, height: 263, image: .rocketFront, contentMode: .scaleAspectFit)
                        }
                    }.padding(.init(only: .top, inset: 30))
                    UILabel(text: L10n.topUpYourAccountToGetStarted, textSize: 28, weight: .bold, numberOfLines: 3, textAlignment: .center)
                    UIView(height: 10)
                    UILabel(text: L10n.makeYourFirstDepositOrBuyWithYourCreditCardOrApplePay, textColor: .secondaryLabel, numberOfLines: 3, textAlignment: .center)
                    UIView(height: 25)
                    
                    // Buttons
                    ColorfulHorizontalView {
                        WalletActionButton(actionType: .buy) { [unowned self] in viewModel.navigate(to: .buyToken) }
                        WalletActionButton(actionType: .receive) { [unowned self] in viewModel.navigate(to: .receiveToken) }
                        WalletActionButton(actionType: .send) { [unowned self] in viewModel.navigate(to: .sendToken()) }
                        WalletActionButton(actionType: .swap) { [unowned self] in viewModel.navigate(to: .swapToken) }
                    }.frame(height: 80)
                    
                    UIView.spacer
                }.padding(.init(x: 18, y: 0))
            }
        }
        
        @objc func reload() {
            viewModel.walletsRepository.reload()
        }
    }
    
    class CircleGradientView: UIView {
        let effectLayer: CAGradientLayer = {
            let l = CAGradientLayer()
            l.type = .radial
            l.colors = [
                UIColor(red: 0.35, green: 0.53, blue: 1.00, alpha: 1.0).cgColor,
                UIColor(red: 0.35, green: 0.53, blue: 1.00, alpha: 0.0).cgColor,
            ]
            l.locations = [0, 0.8]
            l.startPoint = .init(x: 0.5, y: 0.5)
            l.endPoint = CGPoint(x: 1, y: 1)
            
            return l
        }()
        
        override func layoutSubviews() {
            super.layoutSubviews()
            if effectLayer.superlayer == nil {
                layer.addSublayer(effectLayer)
            }
            effectLayer.frame = bounds
            alpha = 0.2
        }
    }
}
