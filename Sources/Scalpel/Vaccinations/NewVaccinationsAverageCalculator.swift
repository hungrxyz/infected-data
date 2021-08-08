//
//  NewVaccinationsAverageCalculator.swift
//  
//
//  Created by marko on 3/12/21.
//

import Foundation

struct NewVaccinationsAveragePerWeekCalculator {

    let entries: [VaccinationsEntry]

    func callAsFunction() -> Int {
        var perDay = [Int]()

        for (index, previous) in Array(entries.dropLast()).enumerated() {
            let current = entries[index + 1]

            let diff = current.doses - previous.doses
            perDay.append(diff)
        }

        return perDay.reduce(0, +) / 7
    }

}
