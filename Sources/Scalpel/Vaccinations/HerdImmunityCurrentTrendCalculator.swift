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
        let lastWeekEntries = Array(vaccinationEntries.suffix(3))

        let currentAverageAdministeredPerDay = NewVaccinationsAveragePerWeekCalculator(entries: lastWeekEntries)()
        let currentAverageDosage = lastWeekEntries.reduce(into: 0) { $0 += $1.dosage } / Float(lastWeekEntries.count)
        let currentAverageAdministeredPerPerson = Int(Float(currentAverageAdministeredPerDay) * currentAverageDosage)

        let latestEntry = vaccinationEntries.last!
        let totalFullyVaxxed = Int(Float(latestEntry.doses) * latestEntry.fullyVaxxedPercentage)
        let totalAdministeredGoal = population

        let herdImmunityThreshold = Int(Float(totalAdministeredGoal) * 0.7)

        var daysToGo = 0
        var dayByDay = totalFullyVaxxed

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
