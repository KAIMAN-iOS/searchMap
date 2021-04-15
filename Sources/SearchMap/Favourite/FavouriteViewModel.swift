//
//  File.swift
//  
//
//  Created by GG on 26/10/2020.
//

import UIKit

public enum FavouriteType: Int, Hashable, Codable {
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
    case edit, delete, add, show
    
    var title: String {
        switch self {
        case .edit: return "edit".bundleLocale()
        case .delete: return "delete".bundleLocale()
        case .add: return "plus".bundleLocale()
        case .show: return "star".bundleLocale()
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .edit: return UIImage(systemName: "pencil")
        case .delete: return UIImage(systemName: "star.slash")
        case .add: return UIImage(systemName: "star")
        case .show: return UIImage(systemName: "list.bullet")
        }
    }
    
    var color: UIColor {
        switch self {
        case .edit: return #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1)
        case .delete: return #colorLiteral(red: 1, green: 0.192286253, blue: 0.2298730612, alpha: 1)
        case .add: return #colorLiteral(red: 1, green: 0.192286253, blue: 0.2298730612, alpha: 1)
        case .show: return #colorLiteral(red: 0.6176490188, green: 0.6521512866, blue: 0.7114837766, alpha: 1)
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

public class FavouriteViewModel {
    public weak var favDelegate: FavouriteDelegate!
    public weak var refreshDelegate: RefreshFavouritesDelegate?
    public weak var coordinatorDelegate: FavouriteCoordinatorDelegate?
    public var favourites: [PlacemarkSection: [Placemark]] = [:]
    public static let shared: FavouriteViewModel = FavouriteViewModel()
    
    public var home: Placemark? {
        return favourites.values.flatMap({$0}).filter({ $0.specialFavourite == .home }).first
    }
    public var work: Placemark? {
        return favourites.values.flatMap({$0}).filter({ $0.specialFavourite == .work }).first
    }
    
    private init() { }
    
    func loadFavourites(completion: @escaping (([PlacemarkSection: [Placemark]]) -> Void)) {
        favDelegate?.loadFavourites(completion: { [weak self] favs in
            self?.favourites = favs
            self?.refreshDelegate?.refresh(force: true)
            completion(favs)
        })
    }
    
    func canEdit(_ placemark: Placemark) -> Bool {
        return true
    }
    
    func perform(action: FavouriteEditAction, for place: Placemark?) {
        switch action {
        case .edit:
            guard let place = place else { return }
            coordinatorDelegate?.editFavourite(place)
            
        case .delete:
            guard let place = place else { return }
            coordinatorDelegate?.deleteFavourite(place)
            
        case .add:
            coordinatorDelegate?.addNewFavourite()
            
        case .show:
            coordinatorDelegate?.showFavourites()
        }
    }
    
    func actions(for place: Placemark,
                 showFavListButton: Bool = true) -> [FavouriteEditAction]? {
        guard favourites.values.contains([place]) else { return nil }
        return showFavListButton ? [.delete, .edit, .show] : [.delete, .edit]
    }
    
    func contextMenuConfiguration(for place: Placemark?,
                                  specificType: FavouriteType? = nil,
                                  showFavListButton: Bool = true,
                                  selectCompletion: ((FavouriteEditAction, Placemark?) -> Void)? = nil) -> UIContextMenuConfiguration? {
        guard let place = place else {
            return specificType == nil ? nil : [FavouriteEditAction.edit, FavouriteEditAction.show].contextMenuConfiguration {  [weak self] action in
                if let completion = selectCompletion {
                    completion(action, nil)
                } else {
                    self?.perform(action: action, for: nil)
                }
            }
        }
        guard let actions = actions(for: place, showFavListButton: showFavListButton) else { return nil }
        return actions.contextMenuConfiguration {  [weak self] action in
            if let completion = selectCompletion {
                completion(action, place)
            } else {
                self?.perform(action: action, for: place)
            }
        }
    }
    
    func swipeActionsConfiguration(for place: Placemark?,
                                   specificType: FavouriteType? = nil,
                                   in tableView: UITableView,
                                   showFavListButton: Bool = true,
                                   selectCompletion: ((FavouriteEditAction, Placemark?) -> Void)? = nil) -> UISwipeActionsConfiguration? {
        guard let place = place else {
            return specificType == nil ? nil : [FavouriteEditAction.edit, FavouriteEditAction.show].swipeActions { [weak self] action in
                if let completion = selectCompletion {
                    completion(action, nil)
                } else {
                    self?.perform(action: action, for: nil)
                }
            }
        }
        guard let actions = actions(for: place, showFavListButton: showFavListButton) else { return nil }
        return actions.swipeActions { [weak self] action in
            tableView.setEditing(false, animated: true)
            if let completion = selectCompletion {
                completion(action, place)
            } else {
                self?.perform(action: action, for: place)
            }
        }
    }
}

