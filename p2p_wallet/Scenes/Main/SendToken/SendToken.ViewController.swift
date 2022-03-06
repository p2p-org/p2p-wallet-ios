//
//  SendToken.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import UIKit
import BEPureLayout
import RxSwift

extension SendToken {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private let viewModel: SendTokenViewModelType
        
        // MARK: - Properties
        private var childNavigationController: UINavigationController!
        
        // MARK: - Initializer
        init(viewModel: SendTokenViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            view.onTap { [weak self] in
                self?.view.endEditing(true)
            }
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            viewModel.loadingStateDriver
                .drive(view.rx.loadableState {[weak self] in
                    self?.viewModel.reload()
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {return}
            switch scene {
            case .back:
                back()
            case .chooseTokenAndAmount(let showAfterConfirmation):
                let vm = ChooseTokenAndAmount.ViewModel(
                    initialAmount: viewModel.getSelectedAmount(),
                    showAfterConfirmation: showAfterConfirmation,
                    selectedNetwork: viewModel.getSelectedNetwork(),
                    sendTokenViewModel: viewModel
                )
                let vc = ChooseTokenAndAmount.ViewController(viewModel: vm)
                
                if showAfterConfirmation {
                    childNavigationController.pushViewController(vc, animated: true)
                } else {
                    childNavigationController = .init(rootViewController: vc)
                    #if DEBUG
                    let label = UILabel(text: "Relay method: \(viewModel.relayMethod.rawValue)", textColor: .red, numberOfLines: 0, textAlignment: .center)
                    view.addSubview(label)
                    label.autoPinEdge(toSuperviewSafeArea: .top)
                    label.autoAlignAxis(toSuperviewAxis: .vertical)
                    let containerView = UIView(forAutoLayout: ())
                    view.addSubview(containerView)
                    containerView.autoPinEdge(.top, to: .bottom, of: label)
                    containerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
                    add(child: childNavigationController, to: containerView)
                    #else
                    add(child: childNavigationController)
                    #endif
                }
            case .chooseRecipientAndNetwork(let showAfterConfirmation, let preSelectedNetwork):
                let vm = ChooseRecipientAndNetwork.ViewModel(
                    showAfterConfirmation: showAfterConfirmation,
                    preSelectedNetwork: preSelectedNetwork,
                    sendTokenViewModel: viewModel,
                    relayMethod: viewModel.relayMethod
                )
                let vc = ChooseRecipientAndNetwork.ViewController(viewModel: vm)
                childNavigationController.pushViewController(vc, animated: true)
            case .confirmation:
                let vc = ConfirmViewController(viewModel: viewModel)
                childNavigationController.pushViewController(vc, animated: true)
            case .processTransaction(let transaction):
                let vm = ProcessTransaction.ViewModel(processingTransaction: transaction)
                let vc = ProcessTransaction.ViewController(viewModel: vm)
                vc.dismissCompletion = { [weak self] in
                    guard let self = self else {return}
                    if self.viewModel.canGoBack {
                        self.back()
                    } else {
                        self.childNavigationController.popToRootViewController(animated: true)
                    }
                }
                present(vc, interactiveDismissalType: .none, completion: nil)
            case .chooseNetwork:
                let vc = SelectNetwork.ViewController(viewModel: viewModel)
                childNavigationController.pushViewController(vc, animated: true)
            }
        }
    }
}
