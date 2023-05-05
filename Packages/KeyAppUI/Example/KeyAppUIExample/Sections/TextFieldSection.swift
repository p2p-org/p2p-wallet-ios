import Foundation
import BEPureLayout
import KeyAppUI
import UIKit

class TextFieldSection: BECompositionView {
    private let decimalSeparator = Bool.random() ? ".": ","
    private let maximumFractionDigits = Int.random(in: 2..<6)
    private let maxVariable = [Double]([100, 1000, 10000000]).randomElement()!
    
    override func build() -> UIView {
        BEVStack(spacing: 10) {
            UILabel(text: "Text Fields", textSize: 22).padding(.init(only: .top, inset: 20))
            
            for i in [true, false] {
                UILabel(text: "UIDecimalTextField, decimalSeparator: \(decimalSeparator), maximumFractionDigits: \(maximumFractionDigits), max: \(maxVariable)", textSize: 10)
                UIDecimalTextField()
                    .setup { tf in
                        tf.decimalSeparator = decimalSeparator
                        tf.maximumFractionDigits = maximumFractionDigits
                        tf.max = maxVariable
                        tf.forwardedDelegate = self
                    }
                
                UILabel(text: "UISeedPhrasesTextView", textSize: 10)
                UISeedPhrasesTextView()
                    .setup { tv in
                        tv.forwardedDelegate = self
                    }
                
                let leftView: UIView = {
                    BEHStack {
                        UILabel(text: "🇦🇷", textSize: 24, weight: .bold)
                        UIImageView(width: 8, height: 16, imageNamed: "expand", contentMode: .scaleAspectFit)
                            .padding(.init(only: .left, inset: 4))
                        BESpacer.spacer
                    }.frame(width: 44, height: 32)
                }()
                
                let rightView: UIView = {
                    BEHStack {
                        BESpacer.spacer
                        UIImageView(width: 14, height: 16, imageNamed: "copy", contentMode: .scaleAspectFit)
                    }.frame(width: 20, height: 32)
                }()
                
                BaseTextFieldView(leftView: leftView, rightView: rightView, isBig: i).setup { input in
                    input.topTip("The tip or an error message")
                    input.bottomTip("The tip or an error message")
                    input.style = .error
                    input.constantPlaceholder = "••••••••••"
                    input.leftViewMode = .always
                    input.rightViewMode = .always
                }

                BaseTextFieldView(leftView: nil, rightView: nil, isBig: i).setup { input in
                    input.style = .default
                    input.topTip("label")
                    input.bottomTip("the tip or an error message")
                    input.placeholder = "Default Placeholder"
                }

                BaseTextFieldView(leftView: nil, rightView: nil, isBig: i).setup { input in
                    input.style = .default
                    input.topTip("label")
                    input.bottomTip("the tip or an error message")
                    input.text = "+44"
                    input.constantPlaceholder = "+44 7400 123456"
                }

                BaseTextFieldView(leftView: nil, rightView: nil, isBig: i).setup { input in
                    input.style = .success
                    input.topTip("label")
                    input.bottomTip("the tip or an error message")
                    input.text = "+44"
                    input.constantPlaceholder = "+44 7400 123456"
                }

                BaseTextFieldView(leftView: nil, rightView: nil, isBig: i).setup { input in
                    input.topTip("The tip or an error message")
                    input.bottomTip("The tip or an error message")
                    input.style = .default
                    input.constantPlaceholder = "••••••••••"
                    input.text = "•••"
                }

                BaseTextFieldView(leftView: nil, rightView: nil, isBig: i).setup { input in
                    input.style = .default
                    input.constantPlaceholder = "••••••••••"
                    input.text = "•••"
                }

                BaseTextFieldView(leftView: nil, rightView: nil, isBig: i).setup { input in
                    input.style = .default
                    input.constantPlaceholder = "••••••••••"
                    input.text = "•••"
                    input.bottomTip("The tip or an error message")
                }

                BaseTextFieldView(leftView: nil, rightView: nil, isBig: i).setup { input in
                    input.style = .default
                    input.constantPlaceholder = "••••••••••"
                    input.text = "secret wor"
                    input.bottomTip("The tip or an error message")
                }
            }
        }
    }
}

extension TextFieldSection: UISeedPhraseTextViewDelegate {
    func seedPhrasesTextView(_ textView: UISeedPhrasesTextView, didEnterPhrases phrases: String) {
        print(phrases)
    }
}

extension TextFieldSection: UIDecimalTextFieldDelegate {
    func decimalTextFieldDidReceiveValue(_ decimalTextField: UIDecimalTextField, value: Double?) {
        print(value)
    }
}
