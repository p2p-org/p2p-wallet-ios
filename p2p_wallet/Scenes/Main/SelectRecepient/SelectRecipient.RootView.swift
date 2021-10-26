//
//  SelectRecipient.RootView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 20.10.2021.
//

import UIKit
import RxSwift
import RxDataSources

extension SelectRecipient {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: SelectRecipientViewModelType
        
        // MARK: - Subviews
        private let navigationBar = TitleWithCloseButtonNavigationBar(title: L10n.recipient)
        private let addressView: UIView
        private let tableView = UITableView()

        // MARK: - Methods
        init(viewModel: SelectRecipientViewModelType) {
            self.viewModel = viewModel
            self.addressView = AddressView(viewModel: viewModel)
                .padding(.init(all: 8), backgroundColor: .a3a5ba.onDarkMode(.h8d8d8d).withAlphaComponent(0.1), cornerRadius: 12)

            super.init(frame: .zero)
        }

        override func commonInit() {
            super.commonInit()

            configureSubviews()
            layout()
            bind()
        }

        // MARK: - Layout
        private func layout() {
            addSubview(navigationBar)
            addSubview(addressView)
            addSubview(tableView)

            NSLayoutConstraint.activate(navigationBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom))
            NSLayoutConstraint.activate(
                [
                    addressView.autoPinEdge(.top, to: .bottom, of: navigationBar),
                    addressView.autoPinEdge(toSuperviewEdge: .leading, withInset: 20),
                    addressView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
                ]
            )

            NSLayoutConstraint.activate(
                [tableView.autoPinEdge(.top, to: .bottom, of: addressView)] + tableView.autoPinEdgesToSuperviewSafeArea(with: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20), excludingEdge: .top)

            )
        }

        private func configureSubviews() {
            addressView.layer.borderWidth = 1
            addressView.layer.borderColor = UIColor.a3a5ba.cgColor

            tableView.register(RecipientCell.self, forCellReuseIdentifier: RecipientCell.cellIdentifier)
            tableView.rx
                .setDelegate(self)
                .disposed(by: disposeBag)
            tableView.separatorStyle = .none
        }
        
        private func bind() {
            navigationBar.closeObservable
                .subscribe(onNext: { [weak viewModel] in
                    viewModel?.closeScene()
                })
                .disposed(by: disposeBag)

            viewModel.recipientSectionsDriver
                .drive(tableView.rx.items(dataSource: createDataSource()))
                .disposed(by: disposeBag)

            tableView.rx.modelSelected(Recipient.self)
                .subscribe(onNext: { [weak viewModel] recipient in
                    viewModel?.recipientSelected(recipient)
                })
                .disposed(by: disposeBag)
        }

        private func createDataSource() -> RxTableViewSectionedReloadDataSource<RecipientsSection> {
            .init(
                configureCell: { _, tableView, _, recipient in
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: RecipientCell.cellIdentifier) as? RecipientCell else {
                        assertionFailure("Wrong cell")
                        return UITableViewCell()
                    }

                    cell.setRecipient(recipient)

                    return cell
                },
                titleForHeaderInSection: { dataSource, sectionIndex in
                    dataSource[sectionIndex].header
                }
            )

        }
    }
}

extension SelectRecipient.RootView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        76
    }
}
