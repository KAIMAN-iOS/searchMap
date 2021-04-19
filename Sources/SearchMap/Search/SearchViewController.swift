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
import ATACommonObjects
import TextFieldExtension

protocol SearchViewControllerDelegate: class {
    func showMapPicker(for location: BookingPlaceType, coordinates: CLLocationCoordinate2D?)
    func close()
}

class SearchViewController: UIViewController {
    var mode: DisplayMode = .driver
    weak var favDelegate: FavouriteDelegate?  {
        didSet {
            viewModel.favDelegate = favDelegate
        }
    }

    static func create(booking: inout CreateRide,
                       searchDelegate: SearchViewControllerDelegate) -> SearchViewController {
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
    lazy var mapButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "map", in: .module, compatibleWith: nil), for: .normal)
        btn.addTarget(self, action: #selector(showMap), for: .touchUpInside)
        return btn
    } ()
    @IBOutlet weak var validateButton: ActionButton!  {
        didSet {
            validateButton.shape = .rounded(value: 10.0)
            validateButton.setTitle("validate".bundleLocale().uppercased(), for: .normal)
            validateButton.actionButtonType = .primary
        }
    }

    @IBOutlet weak var validateContainer: UIView!
    @IBOutlet weak var originTextField: UITextField!  {
        didSet {
            originTextField.placeholder = "Enter origin".bundleLocale()
            originTextField.delegate = self
            originTextField.tintColor = SearchMapController.configuration.palette.primary
            originTextField.addKeyboardControlView(target: originTextField, buttonStyle: .footnote)
        }
    }
    @IBOutlet weak var originIndicator: UIView!  {
        didSet {
            originIndicator.roundedCorners = true
            originIndicator.backgroundColor = SearchMapController.configuration.palette.confirmation
        }
    }

    @IBOutlet weak var destinationTextField: UITextField!  {
        didSet {
            destinationTextField.placeholder = "Enter destination".bundleLocale()
            destinationTextField.delegate = self
            destinationTextField.tintColor = SearchMapController.configuration.palette.primary
            destinationTextField.addKeyboardControlView(target: destinationTextField, buttonStyle: .footnote)
        }
    }
    @IBOutlet weak var destinationIndicator: UIView! {
        didSet {
            destinationIndicator.roundedCorners = true
            destinationIndicator.backgroundColor = SearchMapController.configuration.palette.primary
        }
    }

    @IBOutlet weak var dashView: DottedView!  {
        didSet {
            dashView.orientation = .vertical
            dashView.backgroundColor = .clear
            dashView.dashes = [4, 4]
            dashView.dotColor = SearchMapController.configuration.palette.inactive
        }
    }

    @IBOutlet weak var tableView: UITableView!  {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.register(UINib(nibName: "PlacemarkCell", bundle: .module), forCellReuseIdentifier: "PlacemarkCell")
        }
    }
    @IBOutlet weak var card: UIView!
    var isLoading: Bool = false  {
        didSet {
            switch (isLoading, textFieldHasFocus) {
            case (true, _):
                let loader = UIActivityIndicatorView(style: .medium)
                loader.color = SearchMapController.configuration.palette.primary
                loader.startAnimating()
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loader)
                
            case (false, false):
                navigationItem.rightBarButtonItem = nil
                
            case (false, true):
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: mapButton)
            }
        }
    }

    
    var booking: CreateRide!
    var searchType: BookingPlaceType? = nil
    var originObserver: NSKeyValueObservation?
    var destinationObserver: NSKeyValueObservation?
    let viewModel = SearchViewModel()
    weak var coordinatorDelegate: SearchMapCoordinatorDelegate?  {
        didSet {
            viewModel.coordinatorDelegate = coordinatorDelegate
        }
    }
    
    deinit {
        print("💀 DEINIT \(URL(fileURLWithPath: #file).lastPathComponent)")
        originObserver?.invalidate()
        destinationObserver?.invalidate()
    }
    
    @IBAction func close() {
        searchDelegate?.close()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        DispatchQueue.main.async { [weak self] in
            if self?.booking.ride.fromAddress != nil {
                self?.destinationTextField.becomeFirstResponder()
            } else {
                self?.originTextField.becomeFirstResponder()
            }
        }
    }
    
    var textFieldHasFocus: Bool = false  {
        didSet {
            switch textFieldHasFocus {
            case true:
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: mapButton)
                
            case false:
//                if viewModel.items[.search] == nil {
//                    viewModel.clear(dataSource: datasource)
//                }
                navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    @IBAction func showMap() {
        guard let searchType = searchType else { return }
        searchDelegate?.showMapPicker(for: searchType,
                                      coordinates: searchType == .origin ? booking.ride.fromAddress?.asCoordinates2D : booking.ride.toAddress?.asCoordinates2D)
    }
    
    func didChoose(_ placemark: CLPlacemark) {
        guard let searchType = searchType else { return }
        switch searchType {
        case .origin: booking.ride.fromAddress = placemark.asPlacemark
        case .destination: booking.ride.toAddress = placemark.asPlacemark
        }
    }
    
    lazy var datasource = viewModel.dataSource(for: tableView)
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.displayMode = mode
        view.backgroundColor = SearchMapController.configuration.palette.background
        tableView.backgroundColor = SearchMapController.configuration.palette.background
        hideBackButtonText = true
        handleValidateButton()
        handleObservers()
        handleKeyboard()
        handleTableView()
    }
    
    func handleTableView() {
        tableView.dataSource = datasource
        tableView.delegate = self
        viewModel.refreshDelegate = self
    }
    
    func handleObservers() {
        originTextField.text = booking.ride.fromAddress?.address
        destinationTextField.text = booking.ride.toAddress?.address
        
        originObserver?.invalidate()
        originObserver = booking.ride.observe(\.fromAddress, changeHandler: { [weak self] (booking, change) in
            self?.handleValidateButton()
            guard let origin = booking.fromAddress else { return }
            self?.originTextField.text = origin.address
        })
        destinationObserver?.invalidate()
        destinationObserver = booking.ride.observe(\.toAddress, changeHandler: { [weak self] (booking, change) in
            self?.handleValidateButton()
            guard let destination = booking.toAddress else { return }
            self?.destinationTextField.text = destination.address
        })
    }
    
    func handleKeyboard() {
        NotificationCenter.default.addObserver(forName: UIApplication.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self?.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: frame.height, right: 0)
            self?.textFieldHasFocus = true
        }
        NotificationCenter.default.addObserver(forName: UIApplication.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] _ in
            self?.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
            self?.textFieldHasFocus = false
        }
    }
    
    func handleValidateButton() {
        validateContainer.isHidden = booking.ride.fromAddress == nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        card.layer.cornerRadius = 20.0
        card.addShadow(roundCorners: false, shadowColor: SearchMapController.configuration.palette.mainTexts.cgColor, shadowOffset: CGSize(width: 5, height: 5), shadowRadius: 5, shadowOpacity: 0.2, useMotionEffect: true)
    }
    
    var search: MKLocalSearch!
    func performSearch() {
        guard let text = searchType == .origin ? originTextField.text : destinationTextField.text else {
            // clear TV
            return
        }
        isLoading = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.resultTypes = [.pointOfInterest, .address]
        if let coord = userCoordinates {
            request.region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
        }
        search = MKLocalSearch(request: request)
        search.start { response, _ in
            var items: [Placemark] = []
            defer {
                self.viewModel.applySearchSnapshot(in: self.datasource, results: items, animatingDifferences: true)
                self.isLoading = false
            }
            guard let response = response else {
                return
            }
            items = response.mapItems.compactMap { item -> Placemark in
                item.placemark.asPlacemark
            }
        }
    }
    
    func clearBooking() {
        guard let searchType = searchType else { return }
        switch searchType {
        case .origin: booking.ride.fromAddress = nil
        case .destination: booking.ride.toAddress = nil
        }
    }
    
    func updateBooking(_ place: Placemark) {
        guard let searchType = searchType else { return }
        switch searchType {
        case .origin: booking.ride.fromAddress = place
        case .destination: booking.ride.toAddress = place
        }
    }
}

extension SearchViewController: RefreshFavouritesDelegate {
    func refresh(force: Bool) {
        // reload only if there are no search
        if (viewModel.items[.search] == nil && textFieldHasFocus) || force {
            reload()
        }
    }
    
    func reload() {
        viewModel.reload()
        viewModel.applyPendingSnapshot(in: datasource)
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let place = viewModel.placemark(at: indexPath) else { return }
        updateBooking(place)
        
        if searchType == .origin && booking.ride.toAddress == nil {
            destinationTextField.becomeFirstResponder()
            searchType = .destination
            refresh(force: false)
        } else {
            view.endEditing(true)
        }
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
        search?.cancel()
        // reload history if no search
        if let text = textField.text,
              let textRange = Range(range, in: text),
              text.replacingCharacters(in: textRange, with: string).isEmpty {
            reload()
        } else {
            lastTypeDate = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: dispatchItem)
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        clearBooking()
        search?.cancel()
        reload()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
//        searchType = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.searchType = textField === originTextField ? .origin : .destination
        if textField.text?.isEmpty ?? true == true {
            reload()
        }
    }
}
