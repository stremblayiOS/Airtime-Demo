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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentSizeOrColor(comparedTo: previousTraitCollection) else { return }
        setupStyles()
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

        tableView.register(MyRoomsCell.self, forCellReuseIdentifier: MyRoomsCell.reuseIdentifier)

        dataSource = DataSource(
            tableView: tableView,
            cellProvider: { (tableView, indexPath, cellViewModel) -> UITableViewCell? in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: MyRoomsCell.reuseIdentifier, for: indexPath) as? MyRoomsCell else { return UITableViewCell() }
                cell.setViewModel(cellViewModel)
                return cell
            }
        )
        dataSource.defaultRowAnimation = .none

        tableView.dataSource = dataSource
    }

    func setupConstraints() {
        // Autolayout code if needed
    }

    // Setup sizes, fonts and colors. This will be called several times as the user changes content size and turns dark mode on/off.
    func setupStyles() {
    }

    func setupBindings() {

        viewModel
            .title
            .receive(on: DispatchQueue.main)
            .assign(to: \.title, onWeak: self)
            .store(in: &cancellables)

        viewModel
            .cellViewModels
            .receive(on: DispatchQueue.main)
            .map { $0 as! [MyRoomsCellViewModelImplementation] }
            .sink { [weak self] cellsViewModels in
                guard let self = self else { return }
                self.snapshot = DataSourceSnapshot()
                self.snapshot.appendSections([""])
                self.snapshot.appendItems(cellsViewModels)
                self.dataSource.apply(self.snapshot)
            }
            .store(in: &cancellables)


        viewModel
            .localizedErrorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { localizedErrorMessage in
                self.presentAlert(with: .init(errorMessage: localizedErrorMessage))
            })
            .store(in: &cancellables)

        viewModel
            .isLoading
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { isLoading in
                // TODO: handle loading on any view controller
                // Delay animation for 1.5 seconds (or so) and cancel directly if 1.5 seconds wasn't reached.
                // also, once displayed, display for 2 seconds (or so) minimum so the loading doesn't flash.
                // example interfaces
                // self.showLoading = isLoading
                // isLoading ? self.presentLoading() : self.dismissLoading()
                // isLoading ? someActivityIndicator.startAnimating() ? someActivityIndicator.stopAnimating()
                // etc...
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
