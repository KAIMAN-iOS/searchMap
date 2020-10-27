//
//  File.swift
//  
//
//  Created by GG on 27/10/2020.
//

import UIKit
import KCoordinatorKit

public protocol FavouriteDelegate: class {
    func loadFavourites(completion: @escaping (([PlacemarkSection: [Placemark]]) -> Void))
    func didAddFavourite(_: Placemark)
    func didDeleteFavourite(_: Placemark)
}

class FavouriteCoordinator<DeepLink>: Coordinator<DeepLink> {
    weak var favDelegate: FavouriteDelegate? 
}
