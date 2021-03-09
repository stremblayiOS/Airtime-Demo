//
//  MyRoomsCellViewModel.swift
//  MyRooms
//
//  Created by Germán Azcona on 09/03/2021.
//

import Foundation
import Combine

/// Keys to be used for localization and accesibility
enum MyRoomsCellKeys: String, Localizable {
    case live = "my_rooms___cell___live"
    case notLive = "my_rooms___cell___not_live"
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
        title.value = room.name
        subtitle.value = room.isLive == true ? MyRoomsCellKeys.live.localized : MyRoomsCellKeys.notLive.localized
    }
}
