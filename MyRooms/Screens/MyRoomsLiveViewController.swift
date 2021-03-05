//
//  MyRoomsLiveViewController.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-02-12.
//

import UIKit
import Combine

final class MyRoomsLiveViewController: UITableViewController {

    private let dataAccessService: DataAccessServiceProtocol

    private var rooms: [Room] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private var cancellableBag = Set<AnyCancellable>()

    init(dataAccessService: DataAccessServiceProtocol) {
        self.dataAccessService = dataAccessService
        super.init(style: .plain)

        title = "Live Rooms"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        dataAccessService.getObjects(request: RoomDataAccessRequest.myRoomsLive).sink { _ in } receiveValue: { [weak self] (rooms: [Room]) in
            self?.rooms = rooms
        }.store(in: &cancellableBag)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rooms.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "")

        cell.textLabel?.text = rooms[indexPath.row].name
        cell.detailTextLabel?.text = rooms[indexPath.row].isLive == true ? "live" : "non-live"

        return cell
    }
}

private extension MyRoomsLiveViewController {

    func setup() {
        setupViews()
        setupStyles()
        setupConstraints()
    }

    func setupViews() {
        // Setup delegates and any special initialization
    }

    func setupStyles() {
        // Setup any special style
    }

    func setupConstraints() {
        // Autolayout code
    }
}
