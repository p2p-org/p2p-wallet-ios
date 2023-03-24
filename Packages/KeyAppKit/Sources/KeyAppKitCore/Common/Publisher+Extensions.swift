//
//  File.swift
//
//
//  Created by Giang Long Tran on 06.03.2023.
//

import Combine

extension Publisher where Failure == Never {
    public func weakAssign<T: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<T, Output>,
        on object: T
    ) -> AnyCancellable {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}
