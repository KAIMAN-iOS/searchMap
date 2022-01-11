//
//  File.swift
//  
//
//  Created by GG on 26/10/2020.
//

import UIKit
import TextFieldEffects
import LabelExtension
import FontExtension
import ReverseGeocodingMap
import CoreLocation
import ActionButton
import Ampersand
import ATAViews
import UIViewExtension
import ATACommonObjects

class FavouriteEditViewController: UIViewController {
    static func create(placeMark: Placemark? = nil,
                       favType: FavouriteType?,
                       delegate: FavouriteDelegate,
                       editMode: Bool) -> FavouriteEditViewController {
        let ctrl: FavouriteEditViewController = UIStoryboard(name: "Favourite", bundle: .module).instantiateViewController(identifier: "FavouriteEditViewController") as! FavouriteEditViewController
        ctrl.placeMark = placeMark ?? Placemark(name: nil, address: nil, coordinates: Coordinates(location: kCLLocationCoordinate2DInvalid))
        ctrl.delegate = delegate
        ctrl.favType = favType
        ctrl.editMode = editMode && placeMark?.id != Address.newId
        return ctrl
    }
    private var editMode: Bool = false
    weak var delegate: FavouriteDelegate!
    var favType: FavouriteType?
    var placeMark: Placemark!
    let viewModel = FavouriteEditSearchViewModel()
    @IBOutlet weak var name: ATATextField!  {
        didSet {
            name.textField.placeholder = "Place name".bundleLocale()
            name.textField.font = .applicationFont(forTextStyle: .body)
            name.textField.tintColor = FavouriteListViewController.configuration.palette.primary
            name.textField.textColor = FavouriteListViewController.configuration.palette.mainTexts
        }
    }

    @IBOutlet weak var address: ATATextField!  {
        didSet {
            address.textField.placeholder = "Place address".bundleLocale()
            address.textField.tintColor = FavouriteListViewController.configuration.palette.primary
            address.textField.delegate = self
            address.textField.font = .applicationFont(forTextStyle: .body)
            (address.superview as? UIStackView)?.setCustomSpacing(20, after: address)
            address.textField.textColor = FavouriteListViewController.configuration.palette.mainTexts
        }
    }
    
    @IBOutlet weak var typeStackView: UIStackView!
    @IBOutlet weak var saveButton: ActionButton!  {
        didSet {
            saveButton.actionButtonType = .confirmation
            saveButton.setTitle("save fav".bundleLocale(), for: .normal)
        }
    }

    @IBOutlet weak var pickMapButton: ActionButton!  {
        didSet {
            pickMapButton.actionButtonType = .secondary
            pickMapButton.setTitle("pick on map".bundleLocale(), for: .normal)
        }
    }
    
    @IBAction func showMap() {
        let map = ReverseGeocodingMap.create(delegate: self,
                                             centerCoordinates: CLLocationCoordinate2DIsValid(placeMark.asCoordinates2D) ? placeMark.asCoordinates2D : nil,
                                             conf: FavouriteListViewController.configuration)
        map.showSearchButton = false
        map.title = "pick on map".bundleLocale()
        navigationController?.pushViewController(map, animated: true)
    }
    
    @IBAction func save() {
        placeMark.name = name.textField.text
        if editMode {
            delegate.didUpdateFavourite(placeMark)
        } else {
            delegate.didAddFavourite(placeMark)
        }
    }
    
    lazy var searchDisplayTableview: UITableViewController = {
        let tv = UITableViewController(style: .plain)
        tv.tableView.register(UINib(nibName: "PlacemarkCell", bundle: .module), forCellReuseIdentifier: "PlacemarkCell")
        self.datasource = viewModel.dataSource(for: tv.tableView)
        tv.tableView.dataSource = datasource
        tv.tableView.delegate = self
        return tv
    }()
    lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: self.searchDisplayTableview)
        search.searchResultsUpdater = self
        search.delegate = self
        search.showsSearchResultsController = true
        search.obscuresBackgroundDuringPresentation = true
        search.searchBar.placeholder = "Type something here to search".bundleLocale()
        search.view.tintColor = FavouriteListViewController.configuration.palette.textOnPrimary
        search.searchBar.tintColor = FavouriteListViewController.configuration.palette.textOnPrimary
        search.searchBar.textField?.tintColor = FavouriteListViewController.configuration.palette.textOnPrimary
        search.searchBar.textField?.leftView?.tintColor = FavouriteListViewController.configuration.palette.textOnPrimary
        search.searchBar.textField?.setPlaceHolderTextColor(FavouriteListViewController.configuration.palette.inactive)
        return search
    } ()
    var datasource: FavouriteEditSearchViewModel.DataSource!
    var lastTypeDate: Date = Date()
    lazy var dispatchItem = DispatchWorkItem { [weak self] in
        guard let self = self else { return }
        guard let text = self.searchText else {
            self.clearBooking()
            return
        }
        if abs(self.lastTypeDate.timeIntervalSinceNow) > 0.45 {
            self.viewModel.performSearch(text: text)
        }
    }
    var searchText: String?
    
    func loadSearch() {
        let attributes:[NSAttributedString.Key: Any] = [
            .foregroundColor: FavouriteListViewController.configuration.palette.textOnPrimary,
            .font: UIFont.applicationFont(ofSize: 16)
        ]
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
        navigationItem.searchController = searchController
        searchController.isActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.searchController.searchBar.becomeFirstResponder()
            self?.searchController.searchBar.textField?.textColor = FavouriteListViewController.configuration.palette.textOnPrimary
        }
    }
    
    func loadStackView() {
        [FavouriteType.home, FavouriteType.work, nil].forEach { fav in
            guard let view: FavouriteTypeView = Bundle.module.loadNibNamed("FavouriteTypeView", owner: nil, options: nil)?.first as? FavouriteTypeView else { return }
            view.configure(fav)
            view.isSelected = fav == self.favType
            view.isUserInteractionEnabled = false
            typeStackView.addArrangedSubview(view)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FavouriteListViewController.configuration.palette.background
        loadStackView()
        let newPlacemark = !CLLocationCoordinate2DIsValid(placeMark.coordinates.asCoord2D)
        saveButton.isEnabled = !newPlacemark
        title = newPlacemark ? "New Favourite".bundleLocale() : "Edit Favourite".bundleLocale()
        name.textField.text = placeMark.name
        address.textField.text = placeMark.address
        hideBackButtonText = true
    }
}

extension FavouriteEditViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === address.textField {
            loadSearch()
            return false
        }
        return true
    }
    
    func clearBooking() {
        viewModel.applySearchSnapshot(in: datasource, results: [])
    }
}

extension FavouriteEditViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let place = datasource.itemIdentifier(for: indexPath) else { return }
        didChoose(place)
    }
}

extension FavouriteEditViewController: UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        navigationItem.searchController = nil
    }
}

extension FavouriteEditViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else {
            clearBooking()
            return
        }
        searchText = text
        lastTypeDate = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: dispatchItem)
    }
}

extension FavouriteEditViewController: ReverseGeocodingMapDelegate {
    func geocodingComplete(_: Result<CLPlacemark, Error>) {
        
    }
    
    func search() {
        
    }
    
    func didChoose(_ placemark: CLPlacemark) {
        navigationController?.popViewController(animated: true)
        didChoose(placemark.asPlacemark)
    }
    
    func didChoose(_ placemark: Placemark) {
        self.placeMark.update(from: placemark)
        self.placeMark.specialFavourite = favType
        if name.textField.text?.isEmpty ?? true {
            name.textField.text = placeMark.name
        } else {
            self.placeMark.name = name.textField.text
        }
        address.textField.text = placeMark.address
        saveButton.isEnabled = true
        navigationItem.searchController = nil
    }
}
