//
//  File.swift
//  
//
//  Created by GG on 26/10/2020.
//

import UIKit
import MapKit
import TableViewExtension

protocol Editable: class {
    func canEditRow(at indexPath: IndexPath) -> Bool
}

class PlacemarkDatasource: UITableViewDiffableDataSource<PlacemarkSection, PlacemarkCellType> {
    weak var editableDelegate: Editable?
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return editableDelegate?.canEditRow(at: indexPath) ?? false
    }
}

public protocol RefreshFavouritesDelegate: class {
    func refresh()
}

public class SearchViewModel {
    var favourtiteViewModel: FavouriteViewModel = FavouriteViewModel.shared
    weak var refreshDelegate: RefreshFavouritesDelegate?
    weak var coordinatorDelegate: SearchMapCoordinatorDelegate?
    var handleFavourites: Bool = true
    var sortedSections: [PlacemarkSection] {
        get {
            items.keys.sorted(by: { $0.sortedIndex < $1.sortedIndex })
        }
    }
    
    init() {
        if handleFavourites {
            items[.specificFavourite] = [.specificFavourite(.home, nil), .specificFavourite(.work, nil)]
        }
        loadFavorites()
    }
    
    func loadFavorites() {
        favourtiteViewModel.loadFavourites(completion: { [weak self] favs in
            favs.forEach { key, value in
                switch key {
                case .favourite: self?.items[key] = value.compactMap({ .favourite($0) })
                case .specificFavourite: self?.items[key] = value.compactMap({ place -> PlacemarkCellType? in
                    guard let type = place.specialFavourite else { return nil }
                    return type == .home ? PlacemarkCellType.specificFavourite(.home, place) : PlacemarkCellType.specificFavourite(.work, place)
                })
                case .history: self?.items[key] = value.compactMap({ .history($0) })
                case .search: self?.items[key] = value.compactMap({ .search($0) })
                }
            }
            self?.refreshDelegate?.refresh()
        })
    }

    typealias SnapShot = NSDiffableDataSourceSnapshot<PlacemarkSection, PlacemarkCellType>
    var currentSnapShot: SnapShot!
    var items: [PlacemarkSection: [PlacemarkCellType]] = [:]
    func applySearchSnapshot(in dataSource: PlacemarkDatasource, results: [Placemark], animatingDifferences: Bool = true) {
        currentSnapShot = dataSource.snapshot()
        currentSnapShot.deleteSections(currentSnapShot.sectionIdentifiers)
        currentSnapShot.deleteAllItems()
        currentSnapShot.appendSections([.search])
        let seachCellType = results.compactMap({ PlacemarkCellType.search($0) })
        currentSnapShot.appendItems(seachCellType, toSection: .search)
        items[.search] = seachCellType
        dataSource.apply(currentSnapShot, animatingDifferences: false) {
            print("osiuvno")
        }
    }
    
    func applyPendingSnapshot(in dataSource: PlacemarkDatasource, animatingDifferences: Bool = true) {
        items[.search] = nil
        currentSnapShot = dataSource.snapshot()
        currentSnapShot.deleteSections(currentSnapShot.sectionIdentifiers)
        currentSnapShot.deleteAllItems()
        sortedSections.forEach { section in
            guard let value = items[section] else { return }
            currentSnapShot.appendSections([section])
            switch section {
            case .favourite: currentSnapShot.appendItems(value, toSection: section)
            case .specificFavourite:
                var allFavs: [PlacemarkCellType] = [.specificFavourite(.home, nil), .specificFavourite(.work, nil)]
                value.forEach { cellType in
                    switch cellType {
                    case .specificFavourite(let favType, _):
                        switch favType {
                        case .home:
                            allFavs.remove(at: 0)
                            allFavs.insert(cellType, at: 0)
                            
                        case .work:
                            allFavs.remove(at: 1)
                            allFavs.insert(cellType, at: 1)
                        }
                    default: ()
                    }
                }
                items[.specificFavourite] = Array(allFavs)
                currentSnapShot.appendItems(Array(allFavs), toSection: section)
            case .history: currentSnapShot.appendItems(value, toSection: section)
            case .search: currentSnapShot.appendItems(value, toSection: section)
            }
        }
        dataSource.apply(currentSnapShot, animatingDifferences: false) {
            print("osiuvno")
        }
    }
    
    func dataSource(for tableView: UITableView) -> PlacemarkDatasource {
        let datasource = PlacemarkDatasource(tableView: tableView)  { (tableView, indexPath, model) -> UITableViewCell? in
            guard let cell: PlacemarkCell = tableView.automaticallyDequeueReusableCell(forIndexPath: indexPath) else {
                return nil
            }
            cell.configure(model)
            return cell
        }
        datasource.editableDelegate = self
        return datasource
    }
    
    func placemark(at indexPath: IndexPath) -> Placemark? {
        // fav or history
        guard indexPath.row < items[.search]?.count ?? 0 else {
            switch items[sortedSections[indexPath.section]]?[indexPath.row] {
            case .favourite(let place): return place
            case .history(let place): return place
            case .search(let place): return place
            case .specificFavourite(_, let place): return place
            default: return nil
            }
        }
        switch items[.search]?[indexPath.row] {
        case .search(let place): return place
        default: return nil
        }
    }
    
    func perform(action: FavouriteEditAction, at indexPath: IndexPath) {
        switch action {
        case .edit:
            guard let place = placemark(at: indexPath) else { return }
            FavouriteViewModel.shared.coordinatorDelegate?.editFavourite(place)
            
        case .delete:
            guard let place = placemark(at: indexPath) else { return }
            FavouriteViewModel.shared.coordinatorDelegate?.deleteFavourite(place)
            
        case .add:
            FavouriteViewModel.shared.coordinatorDelegate?.addNewFavourite()
            
        case .show:
            FavouriteViewModel.shared.coordinatorDelegate?.showFavourites()
        }
    }
    
    func actions(at indexPath: IndexPath) -> [FavouriteEditAction]? {
        guard items[.search]?.count ?? 0 == 0 else {
            return nil
        }
        let section = sortedSections[indexPath.section]
        switch section {
        case .favourite, .specificFavourite:
            guard let place = placemark(at: indexPath) else { return nil }
            return favourtiteViewModel.actions(for: place)
            
        default:
            switch items[sortedSections[indexPath.section]]?[indexPath.row] {
            case .favourite: return [.edit, .delete]
            case .specificFavourite(_, let place): return place == nil ? [.edit] : [.edit, .delete]
            default: return [.add, .show]
            }
        }
    }
    
    func contextMenuConfigurationForRow(at indexPath: IndexPath) -> UIContextMenuConfiguration? {
        let section = sortedSections[indexPath.section]
        switch section {
        case .favourite, .specificFavourite:
            return favourtiteViewModel.contextMenuConfiguration(for: placemark(at: indexPath),
                                                                 specificType: section == .specificFavourite ? (indexPath.row == 0 ? .home : .work) : nil,
                                                                 selectCompletion: { [weak self] (action, place) in
                                                                    self?.perform(action: action, at: indexPath)
                                                                 })
            
        default:
            guard let actions = actions(at: indexPath) else { return nil }
            return actions.contextMenuConfiguration { [weak self] action in
                self?.perform(action: action, at: indexPath)
            }
        }
    }
    
    func swipeActionsConfigurationForRow(at indexPath: IndexPath, in tableView: UITableView) -> UISwipeActionsConfiguration? {
        let section = sortedSections[indexPath.section]
        switch section {
        case .favourite, .specificFavourite:
            return favourtiteViewModel.swipeActionsConfiguration(for: placemark(at: indexPath),
                                                                  specificType: section == .specificFavourite ? (indexPath.row == 0 ? .home : .work) : nil,
                                                                  in: tableView,
                                                                  selectCompletion: { [weak self] (action, place) in
                                                                     self?.perform(action: action, at: indexPath)
                                                                  })
            
        default:
            guard let actions = actions(at: indexPath) else { return nil }
            return actions.swipeActions { [weak self] action in
                tableView.setEditing(false, animated: true)
                self?.perform(action: action, at: indexPath)
            }
        }
    }
}

extension SearchViewModel: Editable {
    func canEditRow(at indexPath: IndexPath) -> Bool {
        switch sortedSections[indexPath.section] {
        case .favourite:
            guard let place = placemark(at: indexPath) else { return false }
            return favourtiteViewModel.canEdit(place)
            
        case .specificFavourite:
            // if the specific favs is not found, the specific fav is just empty, we can edit it
            guard let place = placemark(at: indexPath) else { return true }
            return favourtiteViewModel.canEdit(place)
            
        default: return actions(at: indexPath)  != nil
        }
    }
}
