//
//  File.swift
//  
//
//  Created by GG on 26/10/2020.
//

import UIKit

class FavouriteListViewController: UIViewController {
    static func create() -> FavouriteListViewController {
        let ctrl: FavouriteListViewController =  UIStoryboard(name: "Favourite", bundle: .module).instantiateViewController(identifier: "FavouriteListViewController") as! FavouriteListViewController
        return ctrl
    }
    @IBOutlet weak var tableView: UITableView!  {
        didSet {
            tableView.delegate = self
            tableView.tableFooterView = UIView()
            tableView.register(UINib(nibName: "PlacemarkCell", bundle: .module), forCellReuseIdentifier: "PlacemarkCell")
        }
    }
    let viewModel = FavouriteListViewModel()
    
    @IBAction func addNewFavourite() {
        FavouriteViewModel.shared.coordinatorDelegate?.addNewFavourite()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "My Favourites".bundleLocale()
        navigationController?.navigationBar.prefersLargeTitles = true
        handleTableView()
        if #available(iOS 14.0, *) {
            self.navigationItem.backButtonDisplayMode = .minimal
        } else {
            navigationItem.backButtonTitle = ""
        }
    }
    
    lazy var datasource = viewModel.dataSource(for: tableView)
    func handleTableView() {
        tableView.dataSource = datasource
        tableView.delegate = self
        FavouriteViewModel.shared.refreshDelegate = self
        viewModel.applySnapshot(in: datasource)
    }
}

extension FavouriteListViewController: RefreshFavouritesDelegate {
    func refresh() {
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
    }
}
