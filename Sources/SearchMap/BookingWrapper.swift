//
//  File.swift
//  
//
//  Created by GG on 24/10/2020.
//

import Foundation
import MapKit
import DateExtension

public enum DateWrapper {
    case now, date(_: Date)
}

enum BookingPlaceType {
    case origin, destination
}

public class BookingWrapper: NSObject {
    @objc dynamic public var origin: Placemark!
    @objc dynamic public var destination: Placemark!
    public var message: String?
    public var options: [String: Any] = [:]
    public var pickUpDate: DateWrapper = .now
}

public class Placemark: NSObject {
    public static func == (lhs: Placemark, rhs: Placemark) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    var name: String?
    var address: String?
    var coordinates: CLLocationCoordinate2D
    var specialFavourite: FavouriteType?
    
//    override func hash(into hasher: inout Hasher) {
//        hasher.combine(name)
//        hasher.combine(address)
//        hasher.combine(coordinates.latitude)
//        hasher.combine(coordinates.longitude)
//    }
    
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
