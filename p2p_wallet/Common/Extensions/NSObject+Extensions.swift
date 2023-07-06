//
//  NSObject+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/01/2021.
//

import Foundation

extension NSObject {
    static func swizzle(originalSelector: Selector, newSelector: Selector) {
        guard let orginalMethod = class_getInstanceMethod(self, originalSelector) else { return }

        guard let myMethod = class_getInstanceMethod(self, newSelector) else { return }

        if class_addMethod(
            self,
            originalSelector,
            method_getImplementation(myMethod),
            method_getTypeEncoding(myMethod)
        ) {
            class_replaceMethod(
                self,
                newSelector,
                method_getImplementation(orginalMethod),
                method_getTypeEncoding(orginalMethod)
            )
        } else {
            method_exchangeImplementations(orginalMethod, myMethod)
        }
    }
}
