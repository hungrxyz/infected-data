//
//  NewVaccinationsAverageTrendCalculator.swift
//  
//
//  Created by marko on 3/13/21.
//

import Foundation

struct NewVaccinationsAverageTrendCalculator {

    let entries: [VaccinationsEntry]

    func callAsFunction() -> Int {
        // 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 [ 18 19 20 ]
        let currentEntries = Array(entries.suffix(3))

        // 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 [ 16 17 18 ] 19 20
        let previousEntries = Array(entries.suffix(5).dropLast(2))

        let currentAverage = NewVaccinationsAveragePerWeekCalculator(entries: currentEntries)()
        let previousAverage = NewVaccinationsAveragePerWeekCalculator(entries: previousEntries)()

        return currentAverage - previousAverage
    }

}
