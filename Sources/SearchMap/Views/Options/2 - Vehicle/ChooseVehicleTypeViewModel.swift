//
//  File.swift
//  
//
//  Created by GG on 11/02/2021.
//

import UIKit
import ATACommonObjects

class ChooseVehicleTypeViewModel {
    enum Section: Int, Hashable {
        case list
    }
    enum CellType: Hashable {
        static func == (lhs: CellType, rhs: CellType) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        case vehicle(_: VehicleType, isSelected: Bool)
        case all(isSelected: Bool)
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .vehicle(let vehicle, let selected):
                hasher.combine(vehicle.rawValue)
                hasher.combine(selected)
                
            case .all(let selected):
                hasher.combine("all")
                hasher.combine(selected)
            }
        }
    }
    private(set) var vehicles: [VehicleType]
    init(vehicles: [VehicleType]) {
        self.vehicles = vehicles
    }
    
    // MARK: - DataSource Diffable
    typealias DataSource = UICollectionViewDiffableDataSource<Section, CellType>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, CellType>
    private var dataSource: DataSource!
    private var sections: [Section] = []
    var selectedIndexPath: IndexPath = IndexPath(row: 0, section: 0)
    
    func dataSource(for collectionView: UICollectionView) -> DataSource {
        // Handle cells
        dataSource = DataSource(collectionView: collectionView) { (collection, indexPath, model) -> UICollectionViewCell? in
            guard let cell: VehicleTypeCell = collectionView.automaticallyDequeueReusableCell(forIndexPath: indexPath) else { return nil }
            switch model {
            case .vehicle(let vehicle, let selected): cell.configure(vehicle, isSelected: selected)
            case .all(let isSelected): cell.configureForAllOptions(isSelected: isSelected)
            }
            return cell
        }
        return dataSource
    }
    
    func applySnapshot(in dataSource: DataSource, animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
        var snap = SnapShot()
        snap.deleteAllItems()
        sections.removeAll()
        snap.appendSections([.list])
        snap.appendItems([.all(isSelected: selectedIndexPath.row == 0)], toSection: .list)
        snap.appendItems(vehicles.compactMap({ CellType.vehicle($0, isSelected: self.selectedIndexPath.row > 0 && $0.rawValue == self.selectedIndexPath.row) }), toSection: .list)
        // add items here
        dataSource.apply(snap, animatingDifferences: animatingDifferences, completion: completion)
    }
    
    // MARK: - CollectionView Layout Modern API
    func layout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (section, env) -> NSCollectionLayoutSection? in
            return self.generateLayout(for: section, environnement: env)
        }
        return layout
    }
    
    func select(at indexPath: IndexPath) {
        selectedIndexPath = indexPath
        applySnapshot(in: dataSource)
    }
    
    func select(_ type: VehicleType?) {
        guard let vehicleType = type,
              let index = vehicles.firstIndex(of: vehicleType) else {
            return
        }
        select(at: IndexPath(row: index + 1, section: 0))
    }
    
    func selectedType() -> VehicleType? {
        guard selectedIndexPath.row > 0 else { return nil }
        return vehicles[selectedIndexPath.row - 1]
    }
    
    private func generateLayout(for section: Int, environnement: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let fullItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                 heightDimension: .absolute(40)))
        fullItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0)
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(vehicles.count > 3 ? 0.95 : 1),
                                                                                        heightDimension: .absolute(40)),
                                                     subitem: fullItem,
                                                     count: 4)
        group.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 10)
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(10)
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
//        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10)
        return section
    }
}
