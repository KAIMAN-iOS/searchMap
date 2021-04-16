//
//  File.swift
//  
//
//  Created by GG on 26/10/2020.
//

import UIKit
import ATAConfiguration

class FavouriteListViewController: UIViewController {
    var mode: DisplayMode = .driver
    weak var favDelegate: FavouriteDelegate!  {
        didSet {
            viewModel.favDelegate = favDelegate
        }
    }
    static var configuration: ATAConfiguration!
    static func create(conf: ATAConfiguration, favDelegate: FavouriteDelegate, favCoordinatorDelegate: FavouriteCoordinatorDelegate) -> FavouriteListViewController {
        FavouriteListViewController.configuration = conf
        let ctrl: FavouriteListViewController =  UIStoryboard(name: "Favourite", bundle: .module).instantiateViewController(identifier: "FavouriteListViewController") as! FavouriteListViewController
        ctrl.favDelegate = favDelegate
        ctrl.favCoordinatorDelegate = favCoordinatorDelegate
        return ctrl
    }
    @IBOutlet weak var tableView: UITableView!  {
        didSet {
            tableView.delegate = self
            tableView.tableFooterView = UIView()
            tableView.register(UINib(nibName: "PlacemarkCell", bundle: .module), forCellReuseIdentifier: "PlacemarkCell")
        }
    }
    weak var favCoordinatorDelegate: FavouriteCoordinatorDelegate!
    let viewModel = FavouriteListViewModel()
    
    @IBAction func addNewFavourite() {
        FavouriteViewModel.shared.coordinatorDelegate?.addNewFavourite()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        hideBackButtonText = true
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewFavourite))
//        navigationController?.navigationBar.prefersLargeTitles = true
        viewModel.displayMode = mode
//        view.backgroundColor = .white
        title = "My Favourites".bundleLocale()
        handleTableView()
    }
    
    lazy var datasource = viewModel.dataSource(for: tableView)
    func handleTableView() {
        tableView.dataSource = datasource
        tableView.delegate = self
        FavouriteViewModel.shared.refreshDelegate = self
        viewModel.applySnapshot(in: datasource, animatingDifferences: false)
    }
    
    func reload() {
        FavouriteViewModel.shared.loadFavourites { _ in  }
        viewModel.loadFavs()
        refresh(force: true)
    }
}

extension FavouriteListViewController: RefreshFavouritesDelegate {
    func refresh(force: Bool) {
        viewModel.applySnapshot(in: datasource)
    }
}

extension FavouriteListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 2
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return FavouriteViewModel.shared.contextMenuConfiguration(for: viewModel.placemark(at: indexPath),
                                                                  specificType: nil,
                                                                  showFavListButton: false)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return FavouriteViewModel.shared.swipeActionsConfiguration(for: viewModel.placemark(at: indexPath),
                                                                  specificType: nil,
                                                                  in: tableView,
                                                                  showFavListButton: false)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let place = viewModel.placemark(at: indexPath) ?? Placemark.default
        let favType: FavouriteType? = indexPath.section == 1 ? nil : (indexPath.row == 0 ? .home : .work)
        favCoordinatorDelegate.editFavourite(place, type: favType)
    }
}
