//
//  Dream.swift
//  DreamCatch
//
//  Created by Simeon on 1/28/24.
//

import Foundation
import SwiftData

@Model
class Dream {
    var title: String
    var content: String
    var date: Date
    var lucidity: Float
    var isNightmare: Bool
    
    init(title: String = "My Dream", content: String = "", date: Date = .now, lucidity: Float = 0.0, isNightmare: Bool = false) {
        self.title = title
        self.content = content
        self.date = date
        self.lucidity = lucidity
        self.isNightmare = isNightmare
    }
}
