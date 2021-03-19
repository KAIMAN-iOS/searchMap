//
//  File.swift
//  
//
//  Created by GG on 12/02/2021.
//

import UIKit
import ATAGroup
import ActionButton
import PromiseKit
import ATACommonObjects

protocol ChooseGroupNavigationDelegate: NSObjectProtocol {
    func back()
}

class ChooseGroupsView: UIView {
    weak var navDelegate: ChooseGroupNavigationDelegate!
    var booking: CreateRide!
    weak var delegate: SearchRideDelegate!
    static func create(booking: CreateRide, groups: [Group], delegate: SearchRideDelegate) -> ChooseGroupsView {
        let ctrl: ChooseGroupsView = Bundle.module.loadNibNamed("ChooseGroupsView", owner: nil)?.first as! ChooseGroupsView
        ctrl.booking = booking
        ctrl.delegate = delegate
        ctrl.viewModel = ChooseGroupsViewModel(groups: groups)
        ctrl.loadComponents()
        return ctrl
    }
    @IBOutlet weak var title: UILabel!  {
        didSet {
            title.set(text: "Share with groups".bundleLocale().uppercased(), for: .title3, textColor: SearchMapController.configuration.palette.textOnPrimary)
        }
    }
    @IBOutlet weak var shareRideButton: ActionButton!  {
        didSet {
            shareRideButton.actionButtonType = .confirmation
            shareRideButton.setTitle("Share with groups".bundleLocale(), for: .normal)
            shareRideButton.isEnabled = false
        }
    }

    @IBAction func back() {
        navDelegate.back()
    }
    
    var viewModel: ChooseGroupsViewModel!
    @IBOutlet weak var collectionView: UICollectionView!  {
        didSet {
            collectionView.delegate = self
            collectionView.register(UINib(nibName: "ChooseGroupCell", bundle: .module), forCellWithReuseIdentifier: "ChooseGroupCell")
        }
    }
    var datasource: ChooseGroupsViewModel.DataSource!
    func loadComponents() {
        collectionView.collectionViewLayout = viewModel.layout()
        datasource = viewModel.dataSource(for: collectionView)
        collectionView.dataSource = datasource
        viewModel.applySnapshot(in: datasource)
    }
    
    @IBAction func share() {
        shareRideButton.isLoading = true
        delegate
            .share(booking, to: viewModel.selectedGroups)
            .ensure { [weak self]  in
                self?.shareRideButton.isLoading = false
            }
            .done { _ in }
            .catch { _ in }
    }
    
    func enableNextButton() {
        shareRideButton.isEnabled = viewModel.selectedGroups.count > 0
    }
}

extension ChooseGroupsView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.didSelect(itemAt: indexPath)
        collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        enableNextButton()
    }
}
