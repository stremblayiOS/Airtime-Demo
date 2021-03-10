//
//  MyRoomsViewModel.swift
//  MyRooms
//
//  Created by Germán Azcona on 08/03/2021.
//  Copyright © 2021 Samuel Tremblay. All rights reserved.
//

import Foundation
import Combine

/// Keys to be used for localization and accesibility
enum MyRoomsKeys: String, Localizable {
    case title = "my_rooms___title"
}

/// Trend List View Model
protocol MyRoomsViewModel: class {

    /// Title of the screen. To be shown on the navigation bar.
    var title: CurrentValueSubject<String?, Never> { get }

    /// If it's loading the first time or after pull to refresh is triggered this becomes true.
    var isLoading: CurrentValueSubject<Bool, Never> { get }

    /// An error to be shown if something is wrong
    var localizedErrorMessage: CurrentValueSubject<String?, Never> { get }

    /// The cell view models to be shown by the UI.
    var cellViewModels: CurrentValueSubject<[MyRoomsCellViewModel], Never> { get }

    /// Retrieves the list again from the backend. To be used by pull to refresh
    func reload()

    /// String to describe when there are no more visible reddits.
    var noContentDescription: CurrentValueSubject<String?, Never> { get }
}

/// Implementation
final class MyRoomsViewModelImplementation: MyRoomsViewModel {

    var title = CurrentValueSubject<String?, Never>(MyRoomsKeys.title.localized)

    var isLoading = CurrentValueSubject<Bool, Never>(false)

    var localizedErrorMessage = CurrentValueSubject<String?, Never>(nil)

    var cellViewModels = CurrentValueSubject<[MyRoomsCellViewModel], Never>([])

    var noContentDescription = CurrentValueSubject<String?, Never>(nil)

    private var dataAccessService: DataAccessServiceProtocol?

    private var getRoomsCancellable: AnyCancellable?

    init(dataAccessService: DataAccessServiceProtocol?) {
        self.dataAccessService = dataAccessService
        reload()
    }

    func reload() {
        getRoomsCancellable?.cancel()

        getRoomsCancellable = dataAccessService?
            .getObjects(type: Room.self, request: RoomDataAccessRequest.myRooms)
            .trackLoading(to: \.isLoading.value, onWeak: self)
            .trackLocalizableErrorDescription(to: \.localizedErrorMessage.value, onWeak: self)
            .map { $0.compactMap { MyRoomsCellViewModelImplementation(room: $0) } } //TODO: handle with DI
            .sink(receiveCompletion: { _ in

            }, receiveValue: { [weak self] cellViewModels in
                self?.cellViewModels.value = cellViewModels
            })
    }
}
