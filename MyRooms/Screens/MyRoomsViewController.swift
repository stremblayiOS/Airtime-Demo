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

    typealias DataSource = UITableViewDiffableDataSource<String, MyRoomsCellViewModelImplementation>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<String, MyRoomsCellViewModelImplementation>

    private var dataSource: DataSource!
    var snapshot = DataSourceSnapshot()

    private var rooms: [Room] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private var viewModel: MyRoomsViewModel

    private var cancellables = Set<AnyCancellable>()

    init(dataAccessService: DataAccessServiceProtocol) {
        self.dataAccessService = dataAccessService

        self.viewModel = MyRoomsViewModelImplementation(dataAccessService: dataAccessService) //TODO: move to DI

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

        let addBarButtonItem = UIBarButtonItem(systemItem: .add, primaryAction: UIAction(handler: { [weak self] _ in
            self?.createRoom()
        }))

        let trashBarButtonItem = UIBarButtonItem(systemItem: .trash, primaryAction: UIAction(handler: { [weak self] _ in
            self?.dataAccessService.deleteObject(request: RoomDataAccessRequest.deleteAllRooms, nil)
        }))

        navigationItem.rightBarButtonItems = [trashBarButtonItem, addBarButtonItem]

        dataSource = DataSource(
            tableView: tableView,
            cellProvider: { (tableView, indexPath, cellViewModel) -> UITableViewCell? in
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "MyRoomsCell") //TODO: Dequeue reusable
                cell.textLabel?.text = cellViewModel.title.value
                cell.detailTextLabel?.text = cellViewModel.subtitle.value
                return cell
            }
        )
        dataSource.defaultRowAnimation = .none

        tableView.dataSource = dataSource
    }

    func setupConstraints() {
        // Autolayout code
    }

    // Setup sizes, fonts and colors. This will be called several times as the user changes content size and turns dark mode on/off.
    func setupStyles() {
    }

    func setupBindings() {

        viewModel
            .cellViewModels
            .map { $0 as! [MyRoomsCellViewModelImplementation] }
            .sink { [weak self] cellsViewModels in
                guard let self = self else { return }
                self.snapshot = DataSourceSnapshot()
                self.snapshot.appendSections([""])
                self.snapshot.appendItems(cellsViewModels)
                self.dataSource.apply(self.snapshot)
            }
            .store(in: &cancellables)
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
