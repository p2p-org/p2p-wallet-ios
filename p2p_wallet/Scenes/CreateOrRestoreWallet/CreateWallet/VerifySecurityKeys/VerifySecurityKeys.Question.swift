//
// Created by Giang Long Tran on 11.11.21.
//

import Foundation
import RxSwift
import UIKit

protocol QuestionsDelegate: AnyObject {
    func giveAnswer(question: VerifySecurityKeys.Question, answer: String)
}

extension VerifySecurityKeys {
    struct Question: Hashable {
        let index: Int
        let variants: [String]
        let answer: String?

        init(index: Int, variants: [String], answer: String? = nil) {
            self.index = index
            self.variants = variants
            self.answer = answer
        }

        func give(answer: String) -> Question {
            Question(index: index, variants: variants, answer: answer)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(index)
            hasher.combine(variants)
            hasher.combine(answer)
        }

        static func == (lhs: Question, rhs: Question) -> Bool {
            lhs.index == rhs.index
                && lhs.variants == rhs.variants
                && lhs.answer == rhs.answer
        }
    }

    class QuestionsView: BEView, UITableViewDataSource {
        var questions: [Question] {
            didSet {
                tableView.reloadData()
            }
        }

        private let tableView: UITableView = .init()
        weak var delegate: QuestionsDelegate? {
            didSet {
                tableView.reloadData()
            }
        }

        init(questions: [Question] = []) {
            self.questions = questions
            super.init(frame: CGRect.zero)
        }

        override func commonInit() {
            super.commonInit()

            tableView.register(Cell.self, forCellReuseIdentifier: "cell")
            tableView.separatorStyle = .none
            tableView.dataSource = self
            tableView.delaysContentTouches = false

            layout()
        }

        private func layout() {
            addSubview(tableView)
            tableView.autoPinEdgesToSuperviewEdges()
        }

        func numberOfSections(in _: UITableView) -> Int {
            1
        }

        func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
            questions.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! Cell
            cell.question = questions[indexPath.row]
            cell.delegate = delegate
            return cell
        }
    }

    private class Cell: UITableViewCell {
        var question: Question? {
            didSet {
                update()
            }
        }

        private let title: UILabel = .init(textColor: .h8e8e93)
        private let questionsRow: UIStackView = .init(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fillEqually)
        weak var delegate: QuestionsDelegate?

        override init(style: CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            selectionStyle = .none
            contentView.isUserInteractionEnabled = false
            layout()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func layout() {
            let column = UIStackView(axis: .vertical, spacing: 8, alignment: .fill) {
                title.padding(.init(only: .top, inset: 26))
                questionsRow
            }
            addSubview(column)
            column.autoPinEdgesToSuperviewEdges(with: .init(x: 18, y: 0))

            questionsRow.heightAnchor.constraint(equalToConstant: 40).isActive = true
        }

        private func update() {
            guard let question = question else { return }

            title.text = L10n.selectWord(question.index + 1)

            questionsRow.removeAllArrangedSubviews()
            questionsRow.addArrangedSubviews {
                question.variants.enumerated().map { index, key in
                    KeyView(key: key, hideIndex: true, style: question.answer == key ? .selected : .none)
                        .withTag(index)
                        .onTap(self, action: #selector(handleTap))
                }
            }
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let question = question else { return }
            delegate?.giveAnswer(question: question, answer: question.variants[sender.view!.tag])
        }
    }
}

extension Reactive where Base: VerifySecurityKeys.QuestionsView {
    var keys: Binder<[VerifySecurityKeys.Question]> {
        Binder(base) { view, questions in
            view.questions = questions
        }
    }
}
