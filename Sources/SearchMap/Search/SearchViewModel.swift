//
//  File.swift
//  
//
//  Created by GG on 26/10/2020.
//

import UIKit
import MapKit
import TableViewExtension
import ATACommonObjects

protocol Editable: AnyObject {
    func canEditRow(at indexPath: IndexPath) -> Bool
}

class PlacemarkDatasource: UITableViewDiffableDataSource<PlacemarkSection, PlacemarkCellType> {
    weak var editableDelegate: Editable?
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return editableDelegate?.canEditRow(at: indexPath) ?? false
    }
}

public protocol RefreshFavouritesDelegate: NSObjectProtocol {
    func refresh(force: Bool)
}

public class SearchViewModel {
    var favourtiteViewModel: FavouriteViewModel = FavouriteViewModel.shared
    weak var refreshDelegate: RefreshFavouritesDelegate?
    weak var favDelegate: FavouriteDelegate?
    weak var coordinatorDelegate: SearchMapCoordinatorDelegate?
    var handleFavourites: Bool = false
    var sortedSections: [PlacemarkSection] {
        get {
            let sections = items.keys.sorted(by: { $0.sortedIndex < $1.sortedIndex })
            print("sortedSections \(sections)")
            return sections
        }
    }
    var displayMode: DisplayMode = .driver
    
    init() {
        if handleFavourites {
            items[.specificFavourite] = [.specificFavourite(.home, nil), .specificFavourite(.work, nil)]
        }
        reload(withFavourites: true)
    }
    
    func reload(withFavourites: Bool = false) {
        updateHistory()
        if withFavourites {
            loadFavorites()
        }
    }
    
    private func updateHistory() {
        let history = RecentPlacemarkManager.fetchHistory()
        if history.count > 0 {
            items[.history] = history.compactMap({ .history($0) })
        }
    }
    
    private func loadFavorites() {
        items[.specificFavourite] = nil
        items[.favourite] = nil
        favourtiteViewModel.loadFavourites().forEach { key, value in
            switch key {
            case .favourite: items[key] = value.compactMap({ .favourite($0) })
            case .specificFavourite: items[key] = value.compactMap({ place -> PlacemarkCellType? in
                guard let type = place.specialFavourite else { return nil }
                return type == .home ? PlacemarkCellType.specificFavourite(.home, place) : PlacemarkCellType.specificFavourite(.work, place)
            })
            case .history: items[key] = value.compactMap({ .history($0) })
            case .search: items[key] = value.compactMap({ .search($0) })
            }
        }
        refreshDelegate?.refresh(force: false)
    }
    
    private func removeFavsFromHistory() -> [PlacemarkCellType] {
        guard let history = items.filter({ $0.key == .history }).first?.value else { return [] }
        var favs: [Placemark] = []
        items.filter({ $0.key != .history && $0.key != .search }).forEach { section, placemarks in
            favs.append(contentsOf: placemarks.compactMap({ $0.placemark }))
        }
        let favsSet = Set<Placemark>(favs)
        var histSet = Set<Placemark>(history.compactMap({ $0.placemark }))
        histSet.subtract(favsSet)
        let items = Array(RecentPlacemarkManager
            .fetchHistory()
            .filter({ histSet.contains($0) })
            .compactMap({ PlacemarkCellType.history($0) })
            .suffix(RecentPlacemarkManager.numberOfDisplayedItems))
        self.items[.history] = items
        return items
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
            guard let value = items[section], value.isEmpty == false else { return }
            currentSnapShot.appendSections([section])
            switch section {
            case .favourite: currentSnapShot.appendItems(value, toSection: section)
                
            case .specificFavourite:
                var allFavs: [PlacemarkCellType] = []
                value.forEach { cellType in
                    switch cellType {
                    case .specificFavourite(let favType, _):
                        switch favType {
                        case .home:
                            allFavs.insert(cellType, at: 0)
                            
                        case .work:
                            allFavs.append(cellType)
                        }
                    default: ()
                    }
                }
                items[.specificFavourite] = Array(allFavs)
                currentSnapShot.appendItems(Array(allFavs), toSection: section)
                
            case .history:
                let items = removeFavsFromHistory()
                currentSnapShot.appendItems(items, toSection: section)
                
            case .search: currentSnapShot.appendItems(value, toSection: section)
            }
        }
        dataSource.apply(currentSnapShot, animatingDifferences: false) {
            print("osiuvno")
        }
    }
    
    func clear(dataSource: PlacemarkDatasource) {
        currentSnapShot = dataSource.snapshot()
        currentSnapShot.deleteSections(currentSnapShot.sectionIdentifiers)
        currentSnapShot.deleteAllItems()
        dataSource.apply(currentSnapShot, animatingDifferences: false) { }
    }
    
    var datasource: PlacemarkDatasource!
    func dataSource(for tableView: UITableView) -> PlacemarkDatasource {
        let datasource = PlacemarkDatasource(tableView: tableView)  { [weak self] (tableView, indexPath, model) -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let cell: PlacemarkCell = tableView.automaticallyDequeueReusableCell(forIndexPath: indexPath) else {
                return nil
            }
            cell.configure(model, displayMode: self.displayMode)
            cell.favDelegate = self.favDelegate
            cell.refreshDelegate = self.refreshDelegate
            return cell
        }
        datasource.editableDelegate = self
        self.datasource = datasource
        return datasource
    }
    
    func returnAndSave(_ placemark: Placemark) -> Placemark {
        RecentPlacemarkManager.add(placemark)
//        updateHistory()
        return placemark
    }
    
    func placemark(at indexPath: IndexPath) -> Placemark? {
        // fav or history
        guard let item = datasource.itemIdentifier(for: indexPath) else { return nil }
        switch item {
        case .favourite(let place): return returnAndSave(place)
        case .history(let place): return returnAndSave(place)
        case .search(let place): return returnAndSave(place)
        case .specificFavourite(_, let place): return place == nil ? nil : returnAndSave(place!)
        }
    }
    
    func perform(action: FavouriteEditAction, at indexPath: IndexPath) {
        switch action {
        case .edit:
            guard let place = placemark(at: indexPath) else { return }
            FavouriteViewModel.shared.coordinatorDelegate?.editFavourite(place, type: FavouriteViewModel.shared.type(of: place))
            
        case .delete:
            guard let place = placemark(at: indexPath) else { return }
            FavouriteViewModel.shared.coordinatorDelegate?.deleteFavourite(place, type: FavouriteViewModel.shared.type(of: place))
            
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
        guard handleFavourites else { return nil }
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
        guard handleFavourites else { return nil }
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
    
    
    //let list = CityCode.citycodesForCountry(country: "FR")
    func getCityCode(latitude: Double, longitude: Double, completion: @escaping ((String?) -> Void)) {
        
        DispatchQueue.main.async {
            let list = CityCode.citycodesForCountry(country: "FR")
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { items, error in
                guard error == nil, let locality = items?.first?.locality, let list = list else {
                    completion("")
                    return
                }
                let filteredList: [CityCode] = list.filter({ $0.name.range(of: locality, options: [.caseInsensitive, .diacriticInsensitive]) != nil })
                completion(filteredList.first?.code)
                
            }
        }
        
    }
}

extension SearchViewModel: Editable {
    func canEditRow(at indexPath: IndexPath) -> Bool {
        guard handleFavourites else { return false }
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
