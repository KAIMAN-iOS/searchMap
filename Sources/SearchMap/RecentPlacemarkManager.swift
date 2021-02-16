//
//  File.swift
//  
//
//  Created by GG on 16/02/2021.
//

import UIKit
import KStorage

struct RecentPlacemarkManager {
    static private let numberOfItems = 5
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
        try? shared.storage.save(Array(shared.items.suffix(min(RecentPlacemarkManager.numberOfItems, shared.items.count))),
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
