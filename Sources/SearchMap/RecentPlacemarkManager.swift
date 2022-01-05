//
//  File.swift
//  
//
//  Created by GG on 16/02/2021.
//

import UIKit
import KStorage

struct RecentPlacemarkManager {
    static let numberOfDisplayedItems = 5
    static private let numberOfSavedItems = 30
    static let history: StorageKey = "SearchHistory"
    private var storage = DataStorage()
    private static var shared: RecentPlacemarkManager = RecentPlacemarkManager()
    private init() { }
    private var items: Set<HistoryItem> = Set<HistoryItem>()
    
    struct HistoryItem: Codable, Hashable {
        static func == (lhs: HistoryItem, rhs: HistoryItem) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        var placemark: Placemark
        var date: Date = Date()
        func hash(into hasher: inout Hasher) {
            hasher.combine(placemark.coordinates.latitude)
            hasher.combine(placemark.coordinates.longitude)
            hasher.combine(placemark.name)
        }
    }
    
    static func add(_ placemark: Placemark) {
        let history = HistoryItem(placemark: placemark)
        // in case it was search before
        shared.items.remove(history)
        shared.items.insert(history)
        // since history items can have favourite items, we save more items than we display
        try? shared.storage.save(Array(shared.items.suffix(min(RecentPlacemarkManager.numberOfSavedItems, shared.items.count))),
                                 for: RecentPlacemarkManager.history)
    }
    
    static func fetchHistory() -> [Placemark] {
        guard let hist: Set<HistoryItem> = try? shared.storage.fetch(for: RecentPlacemarkManager.history) else {
            return []
        }
        shared.items = hist
        return  shared
            .items
            .sorted(by: { $0.date > $1.date })
            .compactMap({ $0.placemark })
    }
}
