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

    /*
     The case against Published

     I'd love to have used @Published property wrappers, but they can't be accessed through a protocol as far as I found.
     There were some hacky solutions but I figured it was simpler to just expose the properties as `CurrentValueSubject`.
     */

    /// Title of the screen. To be shown on the navigation bar.
    var title: AnyPublisher<String?, Never> { get }

    /// If it's loading the first time or after pull to refresh is triggered this becomes true.
    var isLoading: AnyPublisher<Bool, Never> { get }

    /// The cell view models to be shown by the UI.
    var listItems: AnyPublisher<[TrendListCellViewModel], Never> { get }

    /// Retrieves the list again from the backend. To be used by pull to refresh
    func reload()

    /// String to describe when there are no more visible reddits.
    var noContentDescription: CurrentValueSubject<String?, Never> { get }
}

/// Implementation
final class TrendListViewModelImplementation: MyRoomsViewModel {

    var title = CurrentValueSubject<String?, Never>(MyRoomsKeys.title.localized)

    var isLoading = CurrentValueSubject<Bool, Never>(false)

    var listItems = CurrentValueSubject<[TrendListCellViewModel], Never>([])

    var noContentDescription = CurrentValueSubject<String?, Never>(nil)

    private var dataAccessService: DataAccessServiceProtocol?

    private var repositoriesObserver: NotificationToken?
    private var repositories: DataAccessResults<Repository>? {
        didSet {
            guard oldValue == nil else { return }
            repositoriesObserver = repositories?.observe { [weak self] repos in
                self?.reloadCellViewModels()
            }
        }
    }

    init(dataAccessService: DataAccessServiceProtocol?) {
        self.dataAccessService = dataAccessService
    }

    func reload() {
        dataAccessService?.getObjects(request: RepositoryDataAccessor.getAll) { [weak self] (response: Response<DataAccessResults<Repository>, DataAccessError>) in
            switch response {
            case .success(let repositories):
                self?.repositories = repositories
            case .failure:
                break
            }
        }
    }

    private func reloadCellViewModels() {

        guard let repositories = repositories else { return }

        var items = [TrendListCellViewModel]()
        var iterator = repositories.makeIterator()
        while let item = iterator.next() {
            items.append(TrendListCellViewModel(repository: item))
        }
        listItems.value = items
    }
}

 // */

/// Keys to be used for localization and accesibility
enum MyRoomsCellKeys: String, Localizable {
    case title = "my_rooms___cell___title"
    case subtitle = "my_rooms___cell___subtitle"
    case starCount = "my_rooms___cell___starCount"
}

final class MyRoomsCellViewModel: Hashable {

    static func == (lhs: MyRoomsCellViewModel, rhs: MyRoomsCellViewModel) -> Bool {
        lhs.room == rhs.room
    }

    @Published var title: String? = nil
    @Published var subtitle: String? = nil

    private var room: Room?

    init?(room: Room? = nil) {

        guard let room = room else { return nil }

        self.room = room

        room.objectWillChange.sink { [weak self] in
            self?.title = room.name
            self?.subtitle = room.id
        }

    }
}
