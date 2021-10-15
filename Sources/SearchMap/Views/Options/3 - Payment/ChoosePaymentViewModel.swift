//
//  File.swift
//  
//
//  Created by GG on 12/02/2021.
//

import UIKit
import ImageExtension

public struct CreditCard {
    let number: String
    let expirationDate: String
    let icon: UIImage?
    let id: Int
    
    public init(number: String,
                expirationDate: String,
                icon: UIImage?,
                id: Int) {
        self.number = number
        self.expirationDate = expirationDate
        self.icon = icon
        self.id = id
    }
}

enum PaymentType: Int, Codable {
    case creditCard = 1, change, inApp
}

class ChoosePaymentViewModel {
    enum Section: Int, Hashable {
        case main
    }
    enum CellType: Hashable {
        static func == (lhs: CellType, rhs: CellType) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        case creditCard, change, inApp(_: CreditCard)
        func hash(into hasher: inout Hasher) {
            switch self {
            case .creditCard: hasher.combine(0)
            case .change: hasher.combine(1)
            case .inApp(let card):
                hasher.combine(2)
                hasher.combine(card.id)
            }
        }
        
        var image: UIImage? {
            switch self {
            case .creditCard: return UIImage(named: "creditCard", in: .module, compatibleWith: nil)
            case .change:  return UIImage(named: "change", in: .module, compatibleWith: nil)
            case .inApp(let card):
                let image = card.icon ??  UIImage(named: "creditCard", in: .module, compatibleWith: nil)
                return isActive ? image : image?.grayscale
            }
        }
        
        var typeTitle: String {
            switch self {
            case .creditCard: return "creditCard typeTitle".bundleLocale()
            case .change:  return "change typeTitle".bundleLocale()
            case .inApp: return "inApp typeTitle".bundleLocale()
            }
        }
        
        var title: String {
            switch self {
            case .creditCard: return "creditCard title".bundleLocale()
            case .change:  return "change title".bundleLocale()
            case .inApp(let card): return card.number
            }
        }
        
        var subtitle: String? {
            switch self {
            case .creditCard: return nil
            case .change:  return nil
            case .inApp: return "inApp subtitle".bundleLocale()
            }
        }
        
        var color: UIColor {
            switch self {
            case .creditCard: return SearchMapController.configuration.palette.primary
            case .change:  return SearchMapController.configuration.palette.confirmation
            case .inApp: return SearchMapController.configuration.palette.inactive
            }
        }
        
        var isActive: Bool {
            switch self {
            case .inApp: return false
            default: return true
            }
        }
    }
    
    // MARK: - DataSource Diffable
    typealias DataSource = UICollectionViewDiffableDataSource<Section, CellType>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, CellType>
    private var dataSource: DataSource!
    private var sections: [Section] = []
    var cards: [CreditCard] = []
    var selectedIndexPath: IndexPath = IndexPath(row: 0, section: 0)
    
    init(searchDelegate: SearchRideDelegate) {
        self.cards = searchDelegate.cards()
    }
    
    func dataSource(for collectionView: UICollectionView) -> DataSource {
        dataSource = DataSource(collectionView: collectionView) { [weak self] (collection, indexPath, model) -> UICollectionViewCell? in
            guard let cell: ChoosePaymentCell = collectionView.automaticallyDequeueReusableCell(forIndexPath: indexPath) else { return nil }
            cell.configure(model, isSelected: self?.selectedIndexPath == indexPath)
            return cell
        }
        return dataSource
    }
    
    func applySnapshot(in dataSource: DataSource, animatingDifferences: Bool = false, completion: (() -> Void)? = nil) {
        var snap = SnapShot()
        snap.deleteAllItems()
        sections.removeAll()
        snap.appendSections([.main])
        snap.appendItems([.change, .creditCard], toSection: .main)
        snap.appendItems(cards.compactMap({ CellType.inApp($0) }), toSection: .main)
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
                                                                                 heightDimension: .estimated(123)))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(cards.count > 1 ? 0.95 : 1),
                                                                                        heightDimension: .fractionalHeight(1.0)),
                                                     subitem: fullItem,
                                                     count: 3)
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        return section
    }
    
    func didSelect(itemAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        applySnapshot(in: dataSource)
    }
}
