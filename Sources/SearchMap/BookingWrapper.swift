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

public enum DateWrapper {
    case now, date(_: Date)
    
    var date: Date {
        switch self {
        case .now: return Date()
        case .date(let date): return date
        }
    }
}

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

public enum Option {
    case numberOfPassenger, numberOfLuggages, vehicleType, isMedical
}

public class BookingWrapper: NSObject {
    @objc dynamic public var origin: Placemark!
    @objc dynamic public var destination: Placemark?
    public var message: String?
    public var options: [Option: Int] = [:]
    public var pickUpDate: DateWrapper = .now
}

public struct BookingDirection: Direction {
    public var id: String
    public var startLocation: CLLocationCoordinate2D
    public var endLocation: CLLocationCoordinate2D
}

public struct BookingDirections: Directions {
    public var id: String
    public var directions: [Direction] = []
    
    public init?(_ wrapper: BookingWrapper) {
        id = UUID().uuidString
        guard let dest = wrapper.destination?.coordinates else {
            return nil
        }
        directions.append(BookingDirection(id: UUID().uuidString,
                                           startLocation: wrapper.origin.coordinates,
                                           endLocation: dest))
    }
}

public class Placemark: NSObject {
    public static func == (lhs: Placemark, rhs: Placemark) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    public var name: String?
    public var address: String?
    public var coordinates: CLLocationCoordinate2D
    public var specialFavourite: FavouriteType?
    
    public init(name: String?,
                address: String?,
                coordinates: CLLocationCoordinate2D,
                specialFavourite: FavouriteType? = nil) {
        self.name = name
        self.address = address
        self.coordinates = coordinates
        self.specialFavourite = specialFavourite
    }
}

extension CLPlacemark {
    var asPlacemark: Placemark {
        return Placemark(name: name,
                         address: formattedAddress,
                         coordinates: location?.coordinate ?? kCLLocationCoordinate2DInvalid)
    }
}

extension MKMapItem {
    var asPlacemark: Placemark {
        return placemark.asPlacemark
    }
}
