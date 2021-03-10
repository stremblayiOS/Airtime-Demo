//
//  MyRoomsCell.swift
//  MyRooms
//
//  Created by Germán Azcona on 09/03/2021.
//

import UIKit
import Combine

final class MyRoomsCell: UITableViewCell {

    // TODO: maybe rename to standarizedReuseIdentifier and move to UITableViewCell extension
    // This will prevent dev errors such as typos, copy-pasting wrong, cell renaming and forgetting to change the id, etc.
    static var reuseIdentifier: String {
        return String(describing: self)
    }

    func setViewModel(_ viewModel: MyRoomsCellViewModel) {
        self.textLabel?.text = viewModel.title.value
        self.detailTextLabel?.text = viewModel.subtitle.value
    }
}
