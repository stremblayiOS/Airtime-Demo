//
//  MyRoomsViewController.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-02-12.
//

import UIKit
import Combine

final class MyRoomsViewController: UITableViewController {

    private let dataAccessService: DataAccessServiceProtocol

    typealias DataSource = UITableViewDiffableDataSource<String, Room>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<String, Room>

    private var dataSource: DataSource!
    private var snapshot = DataSourceSnapshot()

    private var rooms: [Room] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    init(dataAccessService: DataAccessServiceProtocol) {
        self.dataAccessService = dataAccessService
        super.init(style: .plain)

        title = "My Rooms"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var cancellableBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        dataAccessService.getObjects(request: RoomDataAccessRequest.myRooms).sink { _ in } receiveValue: { [weak self] (rooms: [Room]) in
            self?.rooms = rooms
        }.store(in: &cancellableBag)

        let addBarButtonItem = UIBarButtonItem(systemItem: .add, primaryAction: UIAction(handler: { [weak self] _ in
            self?.createRoom()
        }))

        let trashBarButtonItem = UIBarButtonItem(systemItem: .trash, primaryAction: UIAction(handler: { [weak self] _ in
            self?.dataAccessService.deleteObject(request: RoomDataAccessRequest.deleteAllRooms, nil)
        }))

        navigationItem.rightBarButtonItems = [trashBarButtonItem, addBarButtonItem]
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}

private extension MyRoomsViewController {

    func setup() {
        setupViews()
        setupConstraints()
        setupStyles()
        setupBindings()
    }

    func setupViews() {

        dataSource = DataSource(tableView: tableView, cellProvider: { (tableView, indexPath, room) -> UITableViewCell? in
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "MyRoomsCell")
            cell.textLabel?.text = room.name
            cell.detailTextLabel?.text = room.isLive == true ? "live" : "non-live"
            return cell
        })

        tableView.dataSource = dataSource
    }

    func setupConstraints() {
        // Autolayout code
    }

    // Setup sizes, fonts and colors. This will be called several times as the user changes content size and turns dark mode on/off.
    func setupStyles() {
    }

    func setupBindings() {
        
    }

    func createRoom() {
        // 1. Create the object and set paramaters
        let room = dataAccessService.createObject(Room.self)
        room.id = UUID().uuidString
        room.name = UUID().uuidString
        room.isLive = Bool.random()

        // 2. Create the request
        let request = RoomDataAccessRequest.create(room: room)

        // 3. Save object
        dataAccessService.saveObject(request: request, nil)
    }
}
