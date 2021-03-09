//
//  Publisher+Extensions.swift
//  MyRooms
//
//  Created by Germán Azcona on 09/03/2021.
//

import Foundation
import Combine

extension Publisher where Self.Failure == Never {

    /// Similar to `assign(to:, on:)` but the object is weakly captured. This is so it can be used on `self` without causing a retain cycle.
    public func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, onWeak object: Root) -> AnyCancellable where Root: AnyObject {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }

    /// Similar to `assign(to:, onWeak:)` but also allows to assign non optional output to an optional property.
    public func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output?>, onWeak object: Root) -> AnyCancellable where Root: AnyObject {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}
