import SwiftUI
import UIKit

extension SwiftUI.Font {
    init(uiFont: UIFont) {
        self = SwiftUI.Font(uiFont as CTFont)
    }
}
