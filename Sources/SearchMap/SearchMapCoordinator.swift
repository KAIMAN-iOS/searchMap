//
//  File.swift
//  
//
//  Created by GG on 23/10/2020.
//

import KCoordinatorKit
import UIKit

public class SearchMapCoordinator<DeepLink>: Coordinator<DeepLink> {
    var standAloneMode: Bool = false
    let searchMapController = SearchMapController.create()
    override init(router: RouterType?) {
        var moduleRouter = router
        if moduleRouter == nil {
            standAloneMode = true
            moduleRouter = Router(navigationController: UINavigationController(rootViewController: searchMapController))
        }
        super.init(router: moduleRouter!)
    }
    
    public override func toPresentable() -> UIViewController {
        return standAloneMode ? router.navigationController : searchMapController
    }
}
