//
//  File.swift
//  
//
//  Created by GG on 27/10/2020.
//

import UIKit
import ATACommonObjects

class FavouriteListViewModel {
    var displayMode: DisplayMode = .driver
    weak var favDelegate: FavouriteDelegate!
    weak var refreshDelegate: RefreshFavouritesDelegate?
    var sortedSections: [PlacemarkSection] {
        get {
            items.keys.sorted(by: { $0.sortedIndex < $1.sortedIndex })
        }
    }
    
    init() {
        loadFavs()
    }
    
    func loadFavs(refresh: Bool = true) {
        FavouriteViewModel.shared.loadFavourites(refresh: refresh)
        var specificTypes: [PlacemarkCellType] = []
        specificTypes.append(.specificFavourite(.home, FavouriteViewModel.shared.home))
        specificTypes.append(.specificFavourite(.work, FavouriteViewModel.shared.work))
        items[.specificFavourite] = specificTypes
        items[.favourite] = FavouriteViewModel.shared.favourites[.favourite]?.compactMap({ place -> PlacemarkCellType? in
            if place.specialFavourite == nil {
                return .favourite(place)
            }
            return nil
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
    
    func applySnapshot(in dataSource: PlacemarkDatasource, animatingDifferences: Bool = false) {
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
        return datasource
    }
    
    func placemark(at indexPath: IndexPath) -> Placemark? {
        // fav or history
        switch items[sortedSections[indexPath.section]]?[indexPath.row] {
        case .favourite(let place): return place
        case .specificFavourite(_, let place): return place
        default: return nil
        }
    }
}

extension FavouriteListViewModel: Editable {
    func canEditRow(at indexPath: IndexPath) -> Bool {
        guard let place = placemark(at: indexPath) else { return true }
        return FavouriteViewModel.shared.canEdit(place)
    }
}

