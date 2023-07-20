import UIKit
import Foundation

/// Delegate for seed phrase text view
@objc public protocol UISeedPhraseTextViewDelegate: AnyObject {
    @objc optional func seedPhrasesTextViewDidBeginEditing(_ textView: UISeedPhrasesTextView)
    @objc optional func seedPhrasesTextViewDidEndEditing(_ textView: UISeedPhrasesTextView)
    @objc optional func seedPhrasesTextViewDidChange(_ textView: UISeedPhrasesTextView)
    func seedPhrasesTextView(_ textView: UISeedPhrasesTextView, didEnterPhrases phrases: String)
}

/// TextView that can handle seed phrase with indexes
public class UISeedPhrasesTextView: UITextView {
    // MARK: - Properties
    
    private static let defaultParagraphStyle: NSMutableParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        return paragraphStyle
    }()
    
    /// Default typing attributes for text
    private static let defaultTypingAttributes: [NSAttributedString.Key: Any] = {
        [
            .font: UIFont.font(of: .text3),
            .foregroundColor: Asset.Colors.night.color,
            .paragraphStyle: defaultParagraphStyle
        ]
    }()
    
    private static let defaultIndexAttributes: [NSAttributedString.Key: Any] = {
        var attributes = defaultTypingAttributes
        attributes[.foregroundColor] = Asset.Colors.mountain.color
        attributes[.font] = UIFont.font(of: .text4)
        return attributes
    }()
    
    /// Regex for Index
    private let indexRegex = try! NSRegularExpression(pattern: #"[0-9]+\s"#)
    
    /// Max index for length. For example "24 " -> 3
    private let maxIndexLength = 3
    
    /// Max index for length. For example "1 " -> 2
    private let minIndexLength = 2
    
    /// Separator between phrases
    private let phraseSeparator = "   " // 3 spaces
    
    /// Mark as pasting
    private var isPasting = false
    
    /// Cache for phrase
    private var phrasesCached = ""
    
    /// Replacement for default delegate
    public weak var forwardedDelegate: UISeedPhraseTextViewDelegate?
    
    /// Prevent default delegation
    public override weak var delegate: UITextViewDelegate? {
        didSet {
            guard let delegate = delegate else {
                return
            }

            if !(delegate is Self) {
                fatalError("Use forwardedDelegate instead")
            }
        }
    }
    
    public override var text: String! {
        didSet {
            fatalError("Don't set text directly, use replaceText(newText:) instead")
        }
    }

    // MARK: - Initializers
    
    /// Default initializer
    public init() {
        super.init(frame: .zero, textContainer: nil)
        isScrollEnabled = false

        backgroundColor = .clear
        tintColor = .black

        typingAttributes = Self.defaultTypingAttributes
//        placeholder = L10n.enterSeedPhrasesInACorrectOrderToRecoverYourWallet
        delegate = self
        layoutManager.delegate = self
        autocapitalizationType = .none
        autocorrectionType = .no
        returnKeyType = .done
    }

    /// Disable initializing with storyboard
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func paste(_ sender: Any?) {
        super.paste(sender)
        isPasting = true
    }

    // MARK: - Methods
    
    /// Get current entered phrases
    public func getPhrases() -> [String] {
        text
            .seedPhraseFormatted
            .components(separatedBy: " ")
            .filter {!$0.isEmpty}
    }
    
    /// Rect for cursor
    public override func caretRect(for position: UITextPosition) -> CGRect {
        var original = super.caretRect(for: position)
        let height: CGFloat = 20
        original.size.height = height
        return original
    }
    
    /// Closest position when dragging
    public override func closestPosition(to point: CGPoint) -> UITextPosition? {
        // FIXME: - Enable choosing in the middle
        let beginning = self.beginningOfDocument
        let end = self.position(from: beginning, offset: self.text?.count ?? 0)
        return end
    }
    
    /// Paste text
    public func replaceText(newText: String) {
        handlePasting(range: .init(location: 0, length: text.count), text: newText)
    }
}

// MARK: - Forward delegate

extension UISeedPhrasesTextView: UITextViewDelegate {
    public func textViewDidBeginEditing(_: UITextView) {
        forwardedDelegate?.seedPhrasesTextViewDidBeginEditing?(self)
    }

    public func textViewDidEndEditing(_: UITextView) {
        forwardedDelegate?.seedPhrasesTextViewDidEndEditing?(self)
    }

    public func textViewDidChange(_: UITextView) {
        forwardedDelegate?.seedPhrasesTextViewDidChange?(self)
    }
    
//    public func textViewDidChangeSelection(_ textView: UITextView) {
//        // FIXME: - Enable selecting in the middle
//        if selectedRange.location + selectedRange.length < text.count {
//            selectedRange = .init(location: text.count, length: 0)
//        }
//    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // pasting
        if isPasting {
            handlePasting(range: range, text: text)
            markAsChanged()
            return false
        }

        // if deleting
        if text.isEmpty {
            handleDeleting(range: range)
            markAsChanged()
            return false
        }

        // add index when found a space
        if text.contains(" ") {
            handleSpace()
            markAsChanged()
            return false
        }
        
        // allow only lowercased letters
        insertOnlyLetters(range: range, text: text)
        markAsChanged()
        return false
    }
    
    // MARK: - Handlers
    
    private func handlePasting(range: NSRange, text: String) {
        let text = text.seedPhraseFormatted

        // find all indexes of spaces
        var indexes = [Int]()
        for (index, char) in text.enumerated() where char == " " {
            indexes.append(index)
        }

        // replace all spaces with phrase separator + index
        var addingAttributedString = NSMutableAttributedString(string: text, attributes: Self.defaultTypingAttributes)
        var lengthDiff = 0
        let phraseIndex = phraseIndex(at: range.location)
        for index in indexes {
            let spaceRange = NSRange(location: index + lengthDiff, length: 1)
            
            // phrase separator
            let replacementAttributedString = NSMutableAttributedString(
                string: phraseSeparator,
                attributes: Self.defaultTypingAttributes
            )
            
            // phrase index
            replacementAttributedString
                .append(indexAttributedString(index: phraseIndex + index))
            
            // replace string with replacement
            addingAttributedString.replaceCharacters(
                in: spaceRange,
                with: replacementAttributedString
            )
            lengthDiff = lengthDiff - 1 + replacementAttributedString.length
        }

        // if stand at the begining add index
        if range.location == 0 {
            addingAttributedString = addingAttributedString
                .prepending(indexAttributedString(index: 1))
        }
        
        // if not stand at the begining and there is no index before it
        else if !hasIndexBeforeLocation(range.location) {
            // add index
            addingAttributedString = addingAttributedString
                .prepending(indexAttributedString(index: phraseIndex + 1))
            
            // add phrase separator (if needed)
            if !hasPhraseSeparatorBeforeLocation(range.location) {
                let phraseSeparator = NSMutableAttributedString(string: phraseSeparator, attributes: Self.defaultTypingAttributes)
                addingAttributedString = addingAttributedString
                    .prepending(phraseSeparator)
            }
        }

        // paste to range
        textStorage.replaceCharacters(in: range, with: addingAttributedString)

        // rearrange
        rearrangeIndexes()

        // move cursor
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {return}
            var newLocation = range.location + addingAttributedString.length
            newLocation = newLocation <= self.text.count ? newLocation: self.text.count
            self.selectedRange = NSRange(location: newLocation, length: 0)
        }
        
        isPasting = false
    }
    
    private func handleDeleting(range: NSRange) {
        // remove
        let firstRemovedCharacter = text[range.location]
        
        if range.length > 1 {
            textStorage.replaceCharacters(in: .init(location: range.location + 1, length: range.length - 1), with: "")
        }
        
        if firstRemovedCharacter != " " {
            textStorage.replaceCharacters(in: .init(location: range.location, length: 1), with: "")
        }
        
        else {
            // remove extra index before
            if let indexRange = rangeOfIndexBeforeLocation(selectedRange.location) {
                textStorage.replaceCharacters(in: indexRange, with: "")
            }
            
            // remove extra phrase separator
            if let phraseSeparatorRange = rangeOfPhraseSeparatorBeforeLocation(selectedRange.location) {
                textStorage.replaceCharacters(in: phraseSeparatorRange, with: "")
            }
        }
        
        // CASE 1: Entire text was removed
        if text.isEmpty {
            insertIndexAtSelectedRangeAndMoveCursor()
            return
        }
        
        // CASE 2: part of text was removed
        rearrangeIndexes()
        selectedRange = .init(location: range.location, length: 0)
    }
    
    private func handleSpace() {
        // won't allow space after a space
        guard !hasSpaceBefore() else { return }
        
        // if user choose all test and press space
        if selectedRange == NSRange(location: 0, length: attributedText.length) {
            textStorage.replaceCharacters(in: selectedRange, with: "")
            insertIndexAtSelectedRangeAndMoveCursor()
            return
        }
        
        // if cursor is in the middle of the text
        let hasIndexAfterCurrentSelectedLocation = hasIndexAfterCurrentSelectedLocation()
        if selectedRange.location > 0 {
            // if there is already an index before current cursor, ignore it
            if hasIndexBeforeLocation(selectedRange.location) {
                return
            }
            // if there is no index before current cursor,
            // add separator
            else if !hasIndexAfterCurrentSelectedLocation {
                insertSeparatorAtSelectedRangeAndMoveCursor()
            }
        }

        // insert index at current selected location
        insertIndexAtSelectedRangeAndMoveCursor()
        
        if hasIndexAfterCurrentSelectedLocation {
            // add separator
            insertSeparatorAtSelectedRangeAndMoveCursor()
            // move back cursor
            selectedRange = .init(location: selectedRange.location - phraseSeparator.count, length: 0)
        }
        
        // rearrange indexes
        rearrangeIndexes()
    }
    
    private func insertOnlyLetters(range: NSRange, text: String) {
        // won't allow ANY character between two spaces
        
        let allowedCharacters = CharacterSet.englishLowercaseLetters
        let characterSet = CharacterSet(charactersIn: text.lowercased())
        
        if allowedCharacters.isSuperset(of: characterSet) {

            // if selected all text
            if range == NSRange(location: 0, length: attributedText.length) {
                textStorage.replaceCharacters(in: range, with: "")
                
                insertIndexAtSelectedRangeAndMoveCursor()
            }
            
            textStorage.replaceCharacters(in: selectedRange, with: NSAttributedString(string: text.lowercased(), attributes: Self.defaultTypingAttributes))
            selectedRange = NSRange(location: selectedRange.location + text.count, length: 0)
        }
    }

    private func rearrangeIndexes() {
        // find all text with index format
        let indexRanges = indexRegex
            .matches(in: text, range: .init(location: 0, length: text.count))
            .map(\.range)
        
        // replace with real index
        var currentPhraseIndex = 1
        var lengthDiff = 0
        for range in indexRanges {
            let indexAttributedString = indexAttributedString(index: currentPhraseIndex)
            textStorage.replaceCharacters(in: .init(location: range.location + lengthDiff, length: range.length), with: indexAttributedString)
            currentPhraseIndex += 1
            lengthDiff = lengthDiff - range.length + indexAttributedString.length
        }
    }
    
    private func markAsChanged() {
        forwardedDelegate?.seedPhrasesTextViewDidChange?(self)
        let newPhrases = getPhrases().joined(separator: " ")
        if newPhrases != phrasesCached {
            forwardedDelegate?.seedPhrasesTextView(self, didEnterPhrases: newPhrases)
            phrasesCached = newPhrases
        }
    }
    
    // MARK: - Helpers

    private func insertSeparatorAtSelectedRangeAndMoveCursor() {
        let separatorAttributedString = NSAttributedString(string: phraseSeparator, attributes: Self.defaultTypingAttributes)
        insertAttributedStringAtSelectedRangeAndMoveCursor(separatorAttributedString)
    }
    
    private func insertIndexAtSelectedRangeAndMoveCursor() {
        let phraseIndex = phraseIndex(at: selectedRange.location)
        let indexAttributedString = indexAttributedString(index: phraseIndex)
        insertAttributedStringAtSelectedRangeAndMoveCursor(indexAttributedString)
    }
    
    private func insertAttributedStringAtSelectedRangeAndMoveCursor(_ attributedString: NSAttributedString) {
        textStorage.replaceCharacters(in: selectedRange, with: attributedString)
        selectedRange = NSRange(location: selectedRange.location + attributedString.length, length: 0)
    }
    
    // MARK: - Checking

    private func hasIndexBeforeLocation(_ location: Int) -> Bool {
        rangeOfIndexBeforeLocation(location) != nil
    }
    
    private func rangeOfIndexBeforeLocation(_ location: Int) -> NSRange? {
        // index max "24 ", min "1 " (min 2 character)
        guard location >= minIndexLength else { return nil}
        
        // check index by using regex
        guard let result = indexRegex.matches(in: text, range: NSRange(location: location > maxIndexLength ? location - maxIndexLength: 0, length: location >= maxIndexLength ? maxIndexLength: minIndexLength)).last
        else {
            return nil
        }
        
        let range = result.range
        
        if range.location + range.length == location {
            return range
        }
        return nil
    }
    
    private func hasIndexAfterCurrentSelectedLocation() -> Bool {
        rangeOfIndexAfterCurrentSelectedLocation() != nil
    }
    
    private func rangeOfIndexAfterCurrentSelectedLocation() -> NSRange? {
        let location = selectedRange.location
        // index max "24 ", min "1 " (max 4 character)
        guard location + minIndexLength <= text.count else { return nil}
        
        // check index by using regex
        guard let result = indexRegex.matches(in: text, range: NSRange(location: location, length: text.count >= location + maxIndexLength ? maxIndexLength: minIndexLength)).first
        else {
            return nil
        }
        
        let range = result.range
        
        if range.location == selectedRange.location {
            return range
        }
        
        return nil
    }
    
    private func hasPhraseSeparatorBeforeLocation(_ location: Int) -> Bool {
        rangeOfPhraseSeparatorBeforeLocation(location) != nil
    }
    
    private func rangeOfPhraseSeparatorBeforeLocation(_ location: Int) -> NSRange? {
        guard location >= phraseSeparator.count else { return nil}
        
        // check index by using regex
        let regex = try! NSRegularExpression(pattern: #"\s{\#(phraseSeparator.count)}"#)
        guard let result = regex.matches(in: text, range: NSRange(location: location - phraseSeparator.count, length: phraseSeparator.count)).last
        else {
            return nil
        }
        
        let range = result.range
        
        if range.location + range.length == location {
            return range
        }
        return nil
    }
    
    private func hasSpaceBefore() -> Bool {
        let location = selectedRange.location
        guard location > 0 else {return false}
        return text[location - 1] == " "
    }
    
    private func hasSpaceAfter() -> Bool {
        let location = selectedRange.location
        guard text.count > location else { return false }
        return text[location - 1] == " "
    }

    // MARK: - AttributedString builders

    private func indexAttributedString(index: Int) -> NSMutableAttributedString {
        .init(string: "\(index) ", attributes: Self.defaultIndexAttributes)
    }

    private func phraseIndex(at location: Int) -> Int {
        let textToLocation = String(text[0..<location])
            .seedPhraseFormatted
            .components(separatedBy: " ")
            .filter {!$0.isEmpty}
        let numberOfPhraseToLocation = textToLocation
            .count
        return numberOfPhraseToLocation + 1
    }
}

private extension NSMutableAttributedString {
    func prepending(_ attributedString: NSAttributedString) -> Self {
        let attributedString = Self(attributedString: attributedString)
        attributedString.append(self)
        return attributedString
    }
}
