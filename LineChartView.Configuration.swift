//
//  LineChartView.Configuration.swift
//  LineChart
//
//  Created by Dauren Yeraly on 08.05.2025.
//

import UIKit

struct Configuration: Hashable {
    
    struct Entry: Hashable, Comparable {
        
        let value: Double
        let label: String?
        
        static func < (lhs: Entry, rhs: Entry) -> Bool {
            return lhs.value < rhs.value
        }
        
        static func == (lhs: Entry, rhs: Entry) -> Bool {
            return lhs.value == rhs.value
        }
    }
    
    let entries: [Entry]
    let lineColor: UIColor
    let gradientColor: [CGColor]
    
    static let empty: Self = .init(entries: [], lineColor: .clear, gradientColor: [])
    
    var isSingleEntry: Bool {
        return entries.count == 1
    }
    
    var allEqual: Bool {
        return Set(entries.map { $0.value }).count == 1
    }
}
