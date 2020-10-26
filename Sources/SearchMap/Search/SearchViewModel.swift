//
//  File.swift
//  
//
//  Created by GG on 26/10/2020.
//

import UIKit
import MapKit
import TableViewExtension

public enum FavouriteType: Int {
    case home, work
    
    var name: String {
        switch self {
        case .home: return "home".bundleLocale()
        case .work: return "work".bundleLocale()
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .home: return UIImage(named: "home", in: .module, with: nil)
        case .work: return UIImage(named: "work", in: .module, with: nil)
        }
    }
}

public protocol FavouriteDisplayDelegate: class {
    func loadFavourites(completion: @escaping (([SearchViewModel.SearchSection: [Placemark]]) -> Void))
}

protocol RefreshFavouritesDelegate: class {
    func refresh()
}

public class SearchViewModel {
    public enum SearchSection {
        case favourite, specificFavourite, history, search
        
        var sortedIndex: Int {
            switch self {
            case .specificFavourite: return 0
            case .favourite: return 1
            case .history: return 2
            case .search: return 3
            }
        }
    }
    enum CellType: Hashable, Equatable {
        static func == (lhs: CellType, rhs: CellType) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        case specificFavourite(_: FavouriteType), favourite(_: Placemark), history(_: Placemark), search(_: Placemark)
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .favourite(let place):
                hasher.combine("favourite")
                hasher.combine(place)
                
            case .specificFavourite(let type):
                hasher.combine("specificFavourite")
                hasher.combine(type)
                
            case .history(let place):
                hasher.combine("history")
                hasher.combine(place)
                
            case .search(let place):
                hasher.combine("search")
                hasher.combine(place)
            }
        }
    }
    // used to load asynchronously the favourites
    weak var favDelegate: FavouriteDisplayDelegate?  {
        didSet {
            favDelegate?.loadFavourites(completion: { [weak self] favs in
                favs.forEach { key, value in
                    self?.items[key] = value
                }
                self?.refreshDelegate?.refresh()
            })
        }
    }
    weak var refreshDelegate: RefreshFavouritesDelegate?

    typealias DataSource = UITableViewDiffableDataSource<SearchSection, CellType>
    typealias SnapShot = NSDiffableDataSourceSnapshot<SearchSection, CellType>
    var currentSnapShot: SnapShot!
    var items: [SearchSection: [Placemark]] = [:]
    func applySearchSnapshot(in dataSource: DataSource, results: [Placemark], animatingDifferences: Bool = true) {
        currentSnapShot = dataSource.snapshot()
        currentSnapShot.deleteSections(currentSnapShot.sectionIdentifiers)
        currentSnapShot.deleteAllItems()
        currentSnapShot.appendSections([.search])
        currentSnapShot.appendItems(results.compactMap({ CellType.search($0) }), toSection: .search)
        items[.search] = results
        dataSource.apply(currentSnapShot, animatingDifferences: false) {
            print("osiuvno")
        }
    }
    
    func applyPendingSnapshot(in dataSource: DataSource, animatingDifferences: Bool = true) {
        items[.search] = nil
        currentSnapShot = dataSource.snapshot()
        currentSnapShot.deleteSections(currentSnapShot.sectionIdentifiers)
        currentSnapShot.deleteAllItems()
        items.sorted(by: { $0.key.sortedIndex < $1.key.sortedIndex }).forEach { key, value in
            currentSnapShot.appendSections([key])
            switch key {
            case .favourite: currentSnapShot.appendItems(value.compactMap({ CellType.favourite($0) }), toSection: key)
            case .specificFavourite: currentSnapShot.appendItems(value.compactMap({$0.specialFavourite}).compactMap({ CellType.specificFavourite($0) }), toSection: key)
            case .history: currentSnapShot.appendItems(value.compactMap({ CellType.history($0) }), toSection: key)
            case .search: currentSnapShot.appendItems(value.compactMap({ CellType.search($0) }), toSection: key)
            }
        }
        dataSource.apply(currentSnapShot, animatingDifferences: false) {
            print("osiuvno")
        }
    }
    
    func dataSource(for tableView: UITableView) -> DataSource {
        let datasource = DataSource(tableView: tableView)  { (tableView, indexPath, model) -> UITableViewCell? in
            guard let cell: SearchResultCell = tableView.automaticallyDequeueReusableCell(forIndexPath: indexPath) else {
                return nil
            }
            cell.configure(model)
            return cell
        }
        return datasource
    }
    
    func placemark(at indexPath: IndexPath) -> Placemark? {
        // fav or history
        guard indexPath.row < items[.search]?.count ?? 0 else {
            let section = items.keys.sorted(by: { $0.sortedIndex < $1.sortedIndex })
            return items[section[indexPath.section]]?[indexPath.row]
        }
        return items[.search]?[indexPath.row]
    }
}
