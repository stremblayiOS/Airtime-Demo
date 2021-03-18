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
    var title: AnyPublisher<String?, Never> { get }

    /// If it's loading the first time or after pull to refresh is triggered this becomes true.
    var isLoading: AnyPublisher<Bool, Never> { get }

    /// The cell view models to be shown by the UI.
    var cellViewModels: AnyPublisher<[MyRoomsCellViewModel], Never> { get }

    /// Retrieves the list again from the backend. To be used by pull to refresh
    func reload()

    /// String to describe when there are no more visible reddits.
    var noContentDescription: CurrentValueSubject<String?, Never> { get }
}

/// Implementation
final class MyRoomsViewModelImplementation: MyRoomsViewModel {

    var titleSubject = CurrentValueSubject<String?, Never>(MyRoomsKeys.title.localized)
    var title: AnyPublisher<String?, Never> { titleSubject.eraseToAnyPublisher() }

    var isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    var isLoading: AnyPublisher<Bool, Never> { isLoadingSubject.eraseToAnyPublisher() }

    var cellViewModelsSubject = CurrentValueSubject<[MyRoomsCellViewModel], Never>([])
    var cellViewModels: AnyPublisher<[MyRoomsCellViewModel], Never> { cellViewModelsSubject.eraseToAnyPublisher() }

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
            //TODO: handle loading state and error alert here
            .map { $0.compactMap { MyRoomsCellViewModelImplementation(room: $0) } } //TODO: handle with DI
            .sink(receiveCompletion: { _ in

            }, receiveValue: { [weak self] cellViewModels in
                self?.cellViewModelsSubject.value = cellViewModels
            })
    }
}

 // */

/// Keys to be used for localization and accesibility
enum MyRoomsCellKeys: String, Localizable {
    case title = "my_rooms___cell___title"
    case subtitle = "my_rooms___cell___subtitle"
    case starCount = "my_rooms___cell___starCount"
}

protocol MyRoomsCellViewModel {

    var title: CurrentValueSubject<String?, Never> { get }
    var subtitle: CurrentValueSubject<String?, Never> { get }

}

final class MyRoomsCellViewModelImplementation: MyRoomsCellViewModel, Hashable {


    func hash(into hasher: inout Hasher) {
        room.hash(into: &hasher)
    }

    static func == (lhs: MyRoomsCellViewModelImplementation, rhs: MyRoomsCellViewModelImplementation) -> Bool {
        lhs.room == rhs.room
    }

    var title = CurrentValueSubject<String?, Never>(nil)
    var subtitle = CurrentValueSubject<String?, Never>(nil)

    private var room: Room
    private var cancellable: AnyCancellable?

    init?(room: Room? = nil) {

        guard let room = room else { return nil }

        self.room = room

        loadRoomInfo()
        cancellable = room.objectWillChange.sink { [weak self] in
            self?.loadRoomInfo()
        }
    }

    func loadRoomInfo() {
        title.value = room.title
//        subtitle.value = room.isLive == true ? "live" : "non-live"
    }
}
