//
//  Item.swift
//  LightWeight
//
//  Created by Buda Sebastian on 02/08/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
