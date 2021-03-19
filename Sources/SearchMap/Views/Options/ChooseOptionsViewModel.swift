//
//  File.swift
//  
//
//  Created by GG on 16/03/2021.
//

import UIKit
import ATACommonObjects

class ChooseOptionsViewModel {
    enum Section: Int, Hashable {
        case main
    }
    struct CellType: Hashable {
        static func == (lhs: CellType, rhs: CellType) -> Bool {
            return lhs.option.rawValue == rhs.option.rawValue
        }
        var option: VehicleOption
        var isSelected: Bool
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(isSelected)
            hasher.combine(option.rawValue)
        }
    }
    private(set) var options: [VehicleOption]
    private(set) var book: CreateRide
    init(options: [VehicleOption], book: inout CreateRide) {
        self.options = options
        self.book = book
    }
    
    // MARK: - DataSource Diffable
    typealias DataSource = UICollectionViewDiffableDataSource<Section, CellType>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, CellType>
    private var dataSource: DataSource!
    private var sections: [Section] = []
    var selectedIndex: Int = -1
    
    func dataSource(for collectionView: UICollectionView) -> DataSource {
        // Handle cells
        dataSource = DataSource(collectionView: collectionView) { (collection, indexPath, model) -> UICollectionViewCell? in
            guard let cell: VehicleTypeCell = collectionView.automaticallyDequeueReusableCell(forIndexPath: indexPath) else { return nil }
            cell.configure(model.option, isSelected: model.isSelected)
            return cell
        }
        return dataSource
    }
    
    func applySnapshot(in dataSource: DataSource, animatingDifferences: Bool = false, completion: (() -> Void)? = nil) {
        var snap = dataSource.snapshot()
        snap.deleteAllItems()
        sections.removeAll()
        snap.appendSections([.main])
        let cellOptions = options.compactMap { option -> CellType in
            CellType(option: option, isSelected: book.vehicleOptions.contains(where: { $0.rawValue == option.rawValue }))
        }
        snap.appendItems(cellOptions, toSection: .main)
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
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        if item.isSelected {
            book.vehicleOptions.removeAll(where: { $0.rawValue == item.option.rawValue })
        } else {
            book.vehicleOptions.append(item.option)
        }
        applySnapshot(in: dataSource)
    }
    
    private func generateLayout(for section: Int, environnement: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let fullItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                 heightDimension: .absolute(40)))
        fullItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0)
        
        let verticalGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                        heightDimension: .fractionalHeight(1)),
                                                     subitem: fullItem,
                                                     count: 2)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(options.count > 4 ? 0.95 : 1),
                                                                                        heightDimension: .fractionalHeight(1)),
                                                     subitem: verticalGroup,
                                                     count: 2)
        group.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 10)
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(10)
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        return section
    }
}
