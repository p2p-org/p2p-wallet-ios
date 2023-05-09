// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeyAppUI
import UIKit

class CodeTemplate {
    public static func share(code: String) {
        UIPasteboard.general.string = code

        let notification = SnackBar(
            icon: Asset.MaterialIcon.copy.image.withTintColor(.white),
            text: "Code template has been copied to clipboard"
        )
        notification.show(in: UIApplication.shared.keyWindow!)
    }
}
