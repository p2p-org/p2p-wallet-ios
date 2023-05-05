// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum JSBError: Error {
    case invalidContext
    case invalidArgument(String)
    case jsError(Any)
    case floatingNumericIsNotSupport
    case pageIsNotReady
}