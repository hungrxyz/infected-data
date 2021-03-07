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
        let last8Entries = Array(vaccinationEntries.suffix(8))

        var perDay = [Int]()

        for (index, previous) in Array(last8Entries.dropLast()).enumerated() {
            let current = last8Entries[index + 1]

            let diff = current.doses - previous.doses
            perDay.append(diff)
        }

        let currentAverageAdministeredPerDay = perDay.reduce(0, +) / perDay.count
        let currentAverageEffectiveness = last8Entries.reduce(into: 0) { $0 += $1.effectiveness } / Float(last8Entries.count)
        let currentAverageAdministeredPerPerson = Int(Float(currentAverageAdministeredPerDay) * currentAverageEffectiveness)

        let latestEntry = vaccinationEntries.last!
        let totalAdministered = Int(Float(latestEntry.doses) * latestEntry.effectiveness)
        let totalAdministeredGoal = population

        let herdImmunityThreshold = Int(Float(totalAdministeredGoal) * 0.7)

        var daysToGo = 0
        var dayByDay = totalAdministered

        while dayByDay < herdImmunityThreshold {
            daysToGo += 1
            dayByDay += currentAverageAdministeredPerPerson
        }

        let todayStartOfDay = calendar.startOfDay(for: Date())
        guard let date = calendar.date(byAdding: .day, value: daysToGo, to: todayStartOfDay) else {
            fatalError("Could not get a god damn date?")
        }

        return date
    }

}
