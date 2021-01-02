//
//  File.swift
//  
//
//  Created by marko on 1/2/21.
//

import Foundation

extension Calendar {

    func isDate(_ date: Date, inSameDayAsDaysAgo days: Int) -> Bool {
        guard let daysAgoDate = self.date(byAdding: .day, value: -days, to: Date.thisMoment) else {
            return false
        }

        return isDate(date, inSameDayAs: daysAgoDate)
    }

}

private extension Date {

    static let thisMoment = Date()

}
