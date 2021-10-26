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
        private let wrappedAddressView: UIView
        private let tableView = UITableView()
        private let errorLabel = UILabel(textSize: 15, weight: .regular, textColor: .ff4444, numberOfLines: 0)
        private lazy var toolBar = KeyboardDependingToolBar(
            nextHandler: { [weak self] in
                self?.endEditing(true)
            },
            pasteHandler: { [weak addressView] in
                addressView?.paste(nil)
            }
        )

        // MARK: - Methods
        init(viewModel: SelectRecipientViewModelType) {
            self.viewModel = viewModel

            self.addressView = AddressView(viewModel: viewModel)
            self.wrappedAddressView = addressView
                .padding(.init(all: 8), backgroundColor: .a3a5ba.onDarkMode(.h8d8d8d).withAlphaComponent(0.1), cornerRadius: 12)

            super.init(frame: .zero)
        }

        override func commonInit() {
            super.commonInit()

            configureSubviews()
            layout()
            bind()
        }

        func startRecipientInput() {
            addressView.becomeFirstResponder()
        }

        // MARK: - Layout
        private func layout() {
            [navigationBar, wrappedAddressView, errorLabel, tableView, toolBar].forEach(addSubview)

            navigationBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)

            wrappedAddressView.autoPinEdge(.top, to: .bottom, of: navigationBar)
            wrappedAddressView.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
            wrappedAddressView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)

            errorLabel.autoPinEdge(.top, to: .bottom, of: wrappedAddressView, withOffset: 8)
            errorLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
            errorLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)

            tableView.autoPinEdge(.top, to: .bottom, of: wrappedAddressView)
            tableView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)

            toolBar.setConstraints()
        }

        private func configureSubviews() {
            wrappedAddressView.layer.borderWidth = 1
            wrappedAddressView.layer.borderColor = UIColor.a3a5ba.withAlphaComponent(0.5).cgColor

            tableView.register(RecipientCell.self, forCellReuseIdentifier: RecipientCell.cellIdentifier)
            tableView.register(
                SelectRecipientSectionHeaderView.self,
                forHeaderFooterViewReuseIdentifier: SelectRecipientSectionHeaderView.identifier
            )
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

            viewModel.searchErrorDriver
                .drive(errorLabel.rx.text)
                .disposed(by: disposeBag)

            let errorIsEmpty = viewModel.searchErrorDriver
                .map { $0 == nil || $0!.isEmpty }

            errorIsEmpty
                .drive(errorLabel.rx.isHidden)
                .disposed(by: disposeBag)

            errorIsEmpty
                .map { !$0 }
                .drive(tableView.rx.isHidden)
                .disposed(by: disposeBag)

            Observable
                .zip(tableView.rx.itemSelected, tableView.rx.modelSelected(Recipient.self))
                .bind { [weak self] indexPath, recipient in
                    self?.tableView.deselectRow(at: indexPath, animated: true)
                    self?.viewModel.recipientSelected(recipient)
                }
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

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: SelectRecipientSectionHeaderView.identifier) as? SelectRecipientSectionHeaderView else {
            assertionFailure("wrong header")
            return nil
        }

        header.setTitle(tableView.dataSource?.tableView?(tableView, titleForHeaderInSection: section))

        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 40 }
}
