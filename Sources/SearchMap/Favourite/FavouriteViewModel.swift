//
//  File.swift
//  
//
//  Created by GG on 26/10/2020.
//

import UIKit

public enum FavouriteType: Int, Hashable {
    case home = 0, work
    
    var name: String {
        switch self {
        case .home: return "Home".bundleLocale()
        case .work: return "Work".bundleLocale()
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .home: return UIImage(named: "home", in: .module, with: nil)
        case .work: return UIImage(named: "work", in: .module, with: nil)
        }
    }
}

enum FavouriteEditAction {
    case edit, delete
    
    var title: String {
        switch self {
        case .edit: return "edit".bundleLocale()
        case .delete: return "delete".bundleLocale()
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .edit: return UIImage(systemName: "pencil")
        case .delete: return UIImage(systemName: "trash")
        }
    }
    
    var color: UIColor {
        switch self {
        case .edit: return #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1)
        case .delete: return #colorLiteral(red: 1, green: 0.192286253, blue: 0.2298730612, alpha: 1)
        }
    }
}

extension Array where Element ==  FavouriteEditAction {
    func swipeActions(swipeCompletion: @escaping ((FavouriteEditAction) -> Void)) -> UISwipeActionsConfiguration {
        var swipeActions: [UIContextualAction] = []
        forEach { action in
            let swipe = UIContextualAction(style: .normal, title: action.title) { (_, view, completionHandler) in
                swipeCompletion(action)
            }
            swipe.backgroundColor = action.color
            swipe.image = action.icon
            swipeActions.append(swipe)
        }
        return UISwipeActionsConfiguration(actions: swipeActions)
    }
    
    func contextMenuConfiguration(selectCompletion: @escaping ((FavouriteEditAction) -> Void)) -> UIContextMenuConfiguration {
        var contextActions: [UIAction] = []
        forEach { action in
            contextActions.append(UIAction(title: action.title, image: action.icon) { _ in
                selectCompletion(action)
            })
        }
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            UIMenu(title: "Actions".local(), children: contextActions)
        }
    }
}

class FavouriteViewModel {
    weak var favDelegate: FavouriteDelegate!
    weak var refreshDelegate: RefreshFavouritesDelegate?
    var favourites: [PlacemarkSection: [Placemark]] = [:]
    
    init(favDelegate: FavouriteDelegate!) {
        self.favDelegate = favDelegate
    }
    
    func loadFavourites(completion: @escaping (([PlacemarkSection: [Placemark]]) -> Void)) {
        favDelegate?.loadFavourites(completion: { [weak self] favs in
            self?.favourites = favs
            self?.refreshDelegate?.refresh()
            completion(favs)
        })
    }
    
    func canEdit(_ placemark: Placemark) -> Bool {
        return true
    }
    
    
    func perform(action: FavouriteEditAction, for place: Placemark) {
        
    }
    
    func actions(for place: Placemark) -> [FavouriteEditAction]? {
        guard favourites.values.contains([place]) else { return nil }
        return [.delete, .edit]
    }
    
    func contextMenuConfiguration(for place: Placemark) -> UIContextMenuConfiguration? {
        guard let actions = actions(for: place) else { return nil }
        var contextActions: [UIAction] = []
        actions.forEach { action in
            contextActions.append(UIAction(title: action.title, image: action.icon) { [weak self] _ in
                self?.perform(action: action, for: place)
            })
        }
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            UIMenu(title: "Actions".local(), children: contextActions)
        }
    }
    
    func swipeActionsConfiguration(for place: Placemark, in tableView: UITableView) -> UISwipeActionsConfiguration? {
        guard let actions = actions(for: place) else { return nil }
        var swipeActions: [UIContextualAction] = []
        actions.forEach { action in
            let swipe = UIContextualAction(style: .normal, title: action.title) { [weak self] (_, view, completionHandler) in
                tableView.setEditing(false, animated: true)
                self?.perform(action: action, for: place)
            }
            swipe.backgroundColor = action.color
            swipe.image = action.icon
            swipeActions.append(swipe)
        }
        
        return UISwipeActionsConfiguration(actions: swipeActions)
    }
}

