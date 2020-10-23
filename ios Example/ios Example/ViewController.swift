//
//  ViewController.swift
//  ios Example
//
//  Created by GG on 23/10/2020.
//

import UIKit
import SearchMap
import KCoordinatorKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    lazy var coord: SearchMapCoordinator<Int> = SearchMapCoordinator(router: Router(navigationController: self.navigationController!))
    @IBAction func show(_ sender: Any) {
        navigationController?.pushViewController(coord.toPresentable(), animated: true)
    }
    
}

