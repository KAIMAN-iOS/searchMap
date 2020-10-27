//
//  File.swift
//  
//
//  Created by GG on 25/10/2020.
//

import UIKit
import UIViewExtension
import MapKit
import CoreLocation
import ActionButton

protocol SearchViewControllerDelegate: class {
    func showMapPicker(for location: BookingPlaceType)
    func close()
}

class SearchViewController: UIViewController {
    static func create(booking: inout BookingWrapper, searchDelegate: SearchViewControllerDelegate) -> SearchViewController {
        let ctrl: SearchViewController =  UIStoryboard(name: "Map", bundle: .module).instantiateViewController(identifier: "SearchViewController") as! SearchViewController
        ctrl.booking = booking
        ctrl.searchDelegate = searchDelegate
        return ctrl
    }
    weak var searchDelegate: SearchViewControllerDelegate?
    var userCoordinates: CLLocationCoordinate2D?
    
    var lastTypeDate: Date = Date()
    lazy var dispatchItem = DispatchWorkItem { [weak self] in
        if abs(self?.lastTypeDate.timeIntervalSinceNow ?? 0) > 0.45 {
            self?.performSearch()
        }
    }
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var validateButton: ActionButton!  {
        didSet {
            validateButton.shape = .rounded(value: 10.0)
            validateButton.setTitle("validate".bundleLocale().uppercased(), for: .normal)
        }
    }

    @IBOutlet weak var validateContainer: UIView!
    @IBOutlet weak var originTextField: UITextField!  {
        didSet {
            originTextField.placeholder = "Enter origin".bundleLocale()
            originTextField.delegate = self
        }
    }
    @IBOutlet weak var originIndicator: UIView!  {
        didSet {
            originIndicator.layer.cornerRadius = originIndicator.bounds.midX
        }
    }

    @IBOutlet weak var destinationTextField: UITextField!  {
        didSet {
            destinationTextField.placeholder = "Enter destination".bundleLocale()
            destinationTextField.delegate = self
        }
    }
    @IBOutlet weak var destinationIndicator: UIView!
    @IBOutlet weak var dashView: UIView!
    @IBOutlet weak var tableView: UITableView!  {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.register(UINib(nibName: "PlacemarkCell", bundle: .module), forCellReuseIdentifier: "PlacemarkCell")
        }
    }
    @IBOutlet weak var card: UIView!
    
    var booking: BookingWrapper!
    var searchType: BookingPlaceType = .origin
    var originObserver: NSKeyValueObservation?
    var destinationObserver: NSKeyValueObservation?
    let viewModel = SearchViewModel()
    
    deinit {
        print("💀 DEINIT \(URL(fileURLWithPath: #file).lastPathComponent)")
        originObserver?.invalidate()
        destinationObserver?.invalidate()
    }
    
    @IBAction func close() {
        searchDelegate?.close()
    }
    
    @IBAction func showMap() {
        let alertController = UIAlertController(title: "For which location do you want to show a map picker ?".bundleLocale(), message: nil, preferredStyle: .alert)
        alertController.view.tintColor = #colorLiteral(red: 1, green: 0.192286253, blue: 0.2298730612, alpha: 1)
        alertController.addAction(UIAlertAction(title: "Cancel".bundleLocale(), style: .cancel, handler: { _ in
            
        }))
        alertController.addAction(UIAlertAction(title: "Origin".bundleLocale(), style: .default, handler: { [weak self] _ in
            self?.searchType = .origin
            self?.searchDelegate?.showMapPicker(for: .origin)
        }))
        alertController.addAction(UIAlertAction(title: "Destination".bundleLocale(), style: .default, handler: { [weak self] _ in
            self?.searchType = .destination
            self?.searchDelegate?.showMapPicker(for: .destination)
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    func didChoose(_ placemark: CLPlacemark) {
        switch searchType {
        case .origin: booking.origin = placemark.asPlacemark
        case .destination: booking.destination = placemark.asPlacemark
        }
    }
    
    lazy var datasource = viewModel.dataSource(for: tableView)
    override func viewDidLoad() {
        super.viewDidLoad()
        handleValidateButton()
        handleObservers()
        handleKeyboard()
        handleTableView()
    }
    
    func handleTableView() {
        tableView.dataSource = datasource
        tableView.delegate = self
        viewModel.refreshDelegate = self
        viewModel.applyPendingSnapshot(in: datasource)
    }
    
    func handleObservers() {
        originTextField.text = booking.origin?.address
        destinationTextField.text = booking.destination?.address
        
        originObserver?.invalidate()
        originObserver = booking.observe(\.origin, changeHandler: { [weak self] (booking, change) in
            self?.handleValidateButton()
            guard let origin = booking.origin else { return }
            self?.originTextField.text = origin.address
        })
        destinationObserver?.invalidate()
        destinationObserver = booking.observe(\.destination, changeHandler: { [weak self] (booking, change) in
            self?.handleValidateButton()
            guard let destination = booking.destination else { return }
            self?.destinationTextField.text = destination.address
        })
    }
    
    func handleKeyboard() {
        NotificationCenter.default.addObserver(forName: UIApplication.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self?.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: frame.height, right: 0)
        }
        NotificationCenter.default.addObserver(forName: UIApplication.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] _ in
            self?.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        }
    }
    
    func handleValidateButton() {
        validateContainer.isHidden = booking.origin == nil || booking.destination == nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        card.layer.cornerRadius = 20.0
        card.addShadow(roundCorners: false, shadowColor: #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1), shadowOffset: CGSize(width: 5, height: 5), shadowRadius: 5, shadowOpacity: 0.2, useMotionEffect: true)
    }
    
    func performSearch() {
        guard let text = searchType == .origin ? originTextField.text : destinationTextField.text else {
            // clear TV
            return
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        if let coord = userCoordinates {
            request.region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
        }
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            let items = response.mapItems.compactMap { item -> Placemark in
                item.placemark.asPlacemark
            }
            print("items \(items)")
            self.viewModel.applySearchSnapshot(in: self.datasource, results: items, animatingDifferences: true)
        }
    }
    
    func clearBooking() {
        switch searchType {
        case .origin: booking.origin = nil
        case .destination: booking.destination = nil
        }
    }
    
    func updateBooking(_ place: Placemark) {
        switch searchType {
        case .origin: booking.origin = place
        case .destination: booking.destination = place
        }
    }
}

extension SearchViewController: RefreshFavouritesDelegate {
    func refresh() {
        // reload only if there are no search
        if viewModel.items[.search] == nil {
            viewModel.applyPendingSnapshot(in: datasource)
        }
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            view.endEditing(true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        guard let place = viewModel.placemark(at: indexPath) else { return }
        
        guard  originTextField.isFirstResponder || destinationTextField.isFirstResponder else {
            let alertController = UIAlertController(title: "For which location do you want to update your journey ?".bundleLocale(), message: "".bundleLocale(), preferredStyle: .alert)
            alertController.view.tintColor = #colorLiteral(red: 1, green: 0.192286253, blue: 0.2298730612, alpha: 1)
            alertController.addAction(UIAlertAction(title: "Cancel".bundleLocale(), style: .cancel, handler: { _ in
            }))
            alertController.addAction(UIAlertAction(title: "Origin".bundleLocale(), style: .default, handler: { [weak self] _ in
                self?.searchType = .origin
                self?.updateBooking(place)
            }))
            alertController.addAction(UIAlertAction(title: "Destination".bundleLocale(), style: .default, handler: { [weak self] _ in
                self?.searchType = .destination
                self?.updateBooking(place)
            }))
            present(alertController, animated: true, completion: nil)
            return
        }
        updateBooking(place)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 2
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return viewModel.contextMenuConfigurationForRow(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return viewModel.swipeActionsConfigurationForRow(at: indexPath, in: tableView)
    }
}

extension SearchViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // reset booking since user typed
        clearBooking()
        lastTypeDate = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: dispatchItem)
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        clearBooking()
        viewModel.applyPendingSnapshot(in: datasource)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.searchType = textField === originTextField ? .origin : .destination
        if textField.text?.isEmpty ?? true == true {
            viewModel.applyPendingSnapshot(in: datasource)
        }
    }
}
