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

extension Publisher {

    /// Simplified loading tracking
    public func trackLoading<Root>(to keyPath: ReferenceWritableKeyPath<Root, Bool>, onWeak object: Root) -> Publishers.HandleEvents<Self> where Root: AnyObject {
        return handleEvents(
            receiveSubscription: { [weak object] _ in
                object?[keyPath: keyPath] = true
            },
            receiveCompletion: { [weak object] _ in
                object?[keyPath: keyPath] = false
            },
            receiveCancel: { [weak object] in
                object?[keyPath: keyPath] = false
            }
        )
    }

    /// Simplified error tracking
    public func trackLocalizableErrorDescription<Root>(to keyPath: ReferenceWritableKeyPath<Root, String?>, onWeak object: Root) -> Publishers.HandleEvents<Self> where Root: AnyObject {
        return handleEvents(
            receiveSubscription: { [weak object] _ in
                object?[keyPath: keyPath] = nil
            },
            receiveCompletion: { [weak object] completion in
                switch completion {
                case .failure(let error):
                    object?[keyPath: keyPath] = error.localizedDescription
                case .finished:
                    object?[keyPath: keyPath] = nil
                }
            },
            receiveCancel: { [weak object] in
                object?[keyPath: keyPath] = nil
            }
        )
    }
}
