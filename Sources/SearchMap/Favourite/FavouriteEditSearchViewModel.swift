//
//  File.swift
//  
//
//  Created by GG on 15/04/2021.
//

import UIKit
import MapKit
import SwiftLocation

class FavouriteEditSearchViewModel {
    enum Section: Int, Hashable {
        case main
    }
    
    // MARK: - DataSource Diffable
    typealias DataSource = UITableViewDiffableDataSource<Section, Placemark>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, Placemark>
    private var dataSource: DataSource!
    private var sections: [Section] = []
    
    func dataSource(for tableView: UITableView) -> DataSource {
        // Handle cells
        dataSource = DataSource(tableView: tableView) { (tableView, indexPath, model) -> UITableViewCell? in
            guard let cell: PlacemarkCell = tableView.automaticallyDequeueReusableCell(forIndexPath: indexPath) else {
                return nil
            }
            cell.configure(model, iconTintColor: FavouriteListViewController.configuration.palette.inactive)
            cell.favButton.isHidden = true
            return cell
        }
        return dataSource
    }
    
    func cancelSearch() {
        search?.cancel()
        search = nil
    }
    
    var search: MKLocalSearch!
    func performSearch(text: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.resultTypes = [.pointOfInterest, .address]
        if let coord = SwiftLocation.lastKnownGPSLocation?.coordinate {
            request.region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
        }
        search = MKLocalSearch(request: request)
        search.start { response, _ in
            var items: [Placemark] = []
            defer {
                self.applySearchSnapshot(in: self.dataSource, results: items, animatingDifferences: true)
            }
            guard let response = response else {
                return
            }
            items = response.mapItems.compactMap { item -> Placemark in
                item.placemark.asPlacemark
            }
        }
    }
    
    var currentSnapShot: SnapShot!
    func applySearchSnapshot(in dataSource: DataSource, results: [Placemark], animatingDifferences: Bool = true) {
        currentSnapShot = SnapShot()
        currentSnapShot.appendSections([.main])
        currentSnapShot.appendItems(results, toSection: .main)
        dataSource.apply(currentSnapShot, animatingDifferences: animatingDifferences) {
            print("osiuvno")
        }
    }
}
