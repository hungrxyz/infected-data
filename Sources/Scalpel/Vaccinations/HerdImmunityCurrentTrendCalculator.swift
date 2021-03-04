//
//  HerdImmunityCurrentTrendCalculator.swift
//  
//
//  Created by marko on 2/28/21.
//

import Foundation

struct HerdImmunityCurrentTrendCalculator {

    let calendar: Calendar
    let vaccinationEntries: [VaccinationsEntry]
    let population: Int

    func callAsFunction() -> Date {
        let last4Entries = Array(vaccinationEntries.suffix(8))

        var perDay = [Int]()

        for (index, previous) in Array(last4Entries.dropLast()).enumerated() {
            let current = last4Entries[index + 1]

            let diff = current.administered - previous.administered
            perDay.append(diff)
        }

        let currentAverageAdministeredPerDay = perDay.reduce(0, +) / perDay.count

        let totalAdministered = vaccinationEntries.last!.administered
        let totalAdministeredGoal = population * 2

        let herdImmunityThreshold = Int(Float(totalAdministeredGoal) * 0.7)

        var daysToGo = 0
        var dayByDay = totalAdministered

        while dayByDay < herdImmunityThreshold {
            daysToGo += 1
            dayByDay += currentAverageAdministeredPerDay
        }

        let todayStartOfDay = calendar.startOfDay(for: Date())
        guard let date = calendar.date(byAdding: .day, value: daysToGo, to: todayStartOfDay) else {
            fatalError("Could not get a god damn date?")
        }

        return date
    }

}
