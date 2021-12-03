//
//  TopAlignLabel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 28.11.2021.
//

class TopAlignLabel: UILabel {
    override func drawText(in rect:CGRect) {
        guard let labelText = text else {  return super.drawText(in: rect) }

        let attributedText = NSAttributedString(
            string: labelText,
            attributes: [
                NSAttributedString.Key.font: font ?? .preferredFont(forTextStyle: .body)
            ]
        )
        var newRect = rect
        newRect.size.height = attributedText.boundingRect(with: rect.size, options: .usesLineFragmentOrigin, context: nil).size.height

        if numberOfLines != 0 {
            newRect.size.height = min(newRect.size.height, CGFloat(numberOfLines) * font.lineHeight)
        }

        super.drawText(in: newRect)
    }
}
