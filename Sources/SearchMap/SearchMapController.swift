//
//  File.swift
//  
//
//  Created by GG on 23/10/2020.
//

import UIKit

class SearchMapController: UIViewController {
    static func create() -> SearchMapController {
        return UIStoryboard(name: "Map", bundle: .module).instantiateInitialViewController() as! SearchMapController
    }
}
