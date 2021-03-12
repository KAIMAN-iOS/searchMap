//
//  File.swift
//  
//
//  Created by GG on 12/02/2021.
//

import UIKit
import ATAGroup

class ChooseGroupsViewModel {
    enum Section: Int, Hashable {
        case main
    }
    
    // MARK: - DataSource Diffable
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Group>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, Group>
    private var dataSource: DataSource!
    private var sections: [Section] = []
    var groups: [Group] = []
    var selectedGroups: [Group] = []
    
    init(groups: [Group]) {
        self.groups = groups.filter({ $0.type.isAlertGroup == false })
    }
    
    func dataSource(for collectionView: UICollectionView) -> DataSource {
        dataSource = DataSource(collectionView: collectionView) { [weak self] (collection, indexPath, model) -> UICollectionViewCell? in
            guard let cell: ChooseGroupCell = collectionView.automaticallyDequeueReusableCell(forIndexPath: indexPath) else { return nil }
            cell.configure(model, isSelected: self?.selectedGroups.contains(model) ?? false)
            return cell
        }
        return dataSource
    }
    
    func applySnapshot(in dataSource: DataSource, animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
        var snap = SnapShot()
        snap.deleteAllItems()
        sections.removeAll()
        snap.appendSections([.main])
        snap.appendItems(groups, toSection: .main)
        dataSource.apply(snap, animatingDifferences: animatingDifferences, completion: completion)
    }
    
    // MARK: - CollectionView Layout Modern API
    func layout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (section, env) -> NSCollectionLayoutSection? in
            return self.generateLayout(for: section, environnement: env)
        }
        return layout
    }
    
    private func generateLayout(for section: Int, environnement: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let fullItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                 heightDimension: .estimated(50)))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(groups.count > 3 ? 0.95 : 1),
                                                                                        heightDimension: .fractionalHeight(1.0)),
                                                     subitem: fullItem,
                                                     count: 3)
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        return section
    }
    
    func didSelect(itemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        if selectedGroups.contains(item) {
            selectedGroups.removeAll(item)
        } else {
            selectedGroups.append(item)
        }
        var snap = dataSource.snapshot()
        snap.reloadItems([item])
        dataSource.apply(snap, animatingDifferences: true)
    }
}
