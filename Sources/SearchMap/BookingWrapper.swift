//
//  File.swift
//  
//
//  Created by GG on 24/10/2020.
//

import Foundation
import MapKit
import DateExtension
import MapExtension
import ATACommonObjects

enum BookingPlaceType {
    case origin, destination
}

public enum PlacemarkSection {
    case favourite, specificFavourite, history, search
    
    var sortedIndex: Int {
        switch self {
        case .specificFavourite: return 0
        case .favourite: return 1
        case .history: return 2
        case .search: return 3
        }
    }
}

enum PlacemarkCellType: Hashable, Equatable {
    static func == (lhs: PlacemarkCellType, rhs: PlacemarkCellType) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    case specificFavourite(_: FavouriteType, _: Placemark?), favourite(_: Placemark), history(_: Placemark), search(_: Placemark)
    var placemark: Placemark? {
        switch self {
        case .specificFavourite(_, let placemark): return placemark
        case .favourite(let placemark): return placemark
        case .history(let placemark): return placemark
        case .search(let placemark): return placemark
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .favourite(let place):
            hasher.combine("favourite")
            hasher.combine(place)
            
        case .specificFavourite(let type, let place):
            hasher.combine("specificFavourite")
            hasher.combine(type)
            hasher.combine(place)
            
        case .history(let place):
            hasher.combine("history")
            hasher.combine(place)
            
        case .search(let place):
            hasher.combine("search")
            hasher.combine(place)
        }
    }
}

public class Placemark: Address {
    public var specialFavourite: FavouriteType?
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(coordinates)
        hasher.combine(name)
        hasher.combine(address)
        return hasher.finalize()
    }
    open override func isEqual(_ object: Any?) -> Bool {
        guard let adress = object as? Address else { return false}
        return self == adress
    }
    static var `default`: Placemark = Placemark(coordinates: Coordinates(location: kCLLocationCoordinate2DInvalid))
    
    enum CodingKeys: String, CodingKey {
        case specialFavourite
    }
    
    public override init(name: String? = nil,
                address: String? = nil,
                coordinates: Coordinates) {
        super.init(name: name, address: address, coordinates: coordinates)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //mandatory
        specialFavourite = try container.decodeIfPresent(FavouriteType.self, forKey: .specialFavourite)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        do {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(specialFavourite, forKey: .specialFavourite)
            try super.encode(to: encoder)
        } catch {
            throw error
        }
    }

}

extension CLPlacemark {
    var asPlacemark: Placemark {
        var address = formattedAddress ?? ""
        if let name = self.name, address.contains(name) == false {
            address.insert(contentsOf: "\(name), ", at: String.Index(utf16Offset: 0, in: address))
        }
        return Placemark(name: name,
                         address: address,
                         coordinates: Coordinates(location: location?.coordinate ?? kCLLocationCoordinate2DInvalid))
    }
}

extension MKMapItem {
    var asPlacemark: Placemark {
        return placemark.asPlacemark
    }
}
