//
//  HerdImmunityEstimationCalculator.swift
//  
//
//  Created by marko on 3/6/21.
//

import Foundation

struct HerdImmunityEstimationCalculator {

    let calendar: Calendar
    let vaccinationEntries: [VaccinationsEntry]
    let vaccinationDeliveries: [VaccinationsEntry]
    let population: Int

    func callAsFunction() -> Date {
        let last8Entries = Array(vaccinationEntries.suffix(8))

        var perDay = [Int]()

        for (index, previous) in Array(last8Entries.dropLast()).enumerated() {
            let current = last8Entries[index + 1]

            let diff = current.doses - previous.doses
            perDay.append(diff)
        }

        let latestEntry = vaccinationEntries.last!
        let totalAdministered = Int(Float(latestEntry.doses) * latestEntry.effectiveness)
        let totalAdministeredGoal = population

        // 70% of population
        let herdImmunityThreshold = Int(Float(totalAdministeredGoal) * 0.7)

        // Averages per quarter
        var averageDeliveriesPerQuarter = [Date: Int]()
        for deliveryEntry in vaccinationDeliveries {
            let daysInQuarter = calendar.range(of: .day, in: .quarter, for: deliveryEntry.date)!.upperBound
            let perPerson = Int(Float(deliveryEntry.doses) * deliveryEntry.effectiveness)
            let average = perPerson / daysInQuarter

            averageDeliveriesPerQuarter[deliveryEntry.date] = average
        }

        let todayStartOfDay = calendar.startOfDay(for: Date())

        var daysToGo = 0
        var dayByDay = totalAdministered
        var lastKnownQuarterStartDate: Date!

        let enumarationDateComponents = DateComponents(hour: 0, minute: 0, second: 0)
        calendar.enumerateDates(startingAfter: todayStartOfDay, matching: enumarationDateComponents, matchingPolicy: .nextTime) { (date, _, shouldStop) in
            let quarterStartDate = calendar.startOfQuarter(for: date!)

            let averagePerDay: Int
            if let knownAveragePerDay = averageDeliveriesPerQuarter[quarterStartDate] {
                averagePerDay = knownAveragePerDay
                lastKnownQuarterStartDate = quarterStartDate
            } else {
                averagePerDay = averageDeliveriesPerQuarter[lastKnownQuarterStartDate]!
            }

            daysToGo += 1
            dayByDay += averagePerDay

            if dayByDay >= herdImmunityThreshold {
                shouldStop = true
            }
        }

        guard let date = calendar.date(byAdding: .day, value: daysToGo, to: todayStartOfDay) else {
            fatalError("Could not get a god damn date?")
        }

        return date
    }

}

private extension Calendar {

    func startOfQuarter(for date: Date) -> Date {
        let year = component(.year, from: date)
        let month = component(.month, from: date)
        let startOfQuarterMonth = month.startOfQuarterMonth

        let components = DateComponents(year: year, month: startOfQuarterMonth, day: 1, hour: 0, minute: 0, second: 0)

        return self.date(from: components)!
    }

}

private extension Int {

    var startOfQuarterMonth: Int {
        switch self {
        case 1, 2, 3:
            return 1
        case 4, 5, 6:
            return 4
        case 7, 8, 9:
            return 7
        case 10, 11, 12:
            return 10
        default:
            fatalError()
        }
    }

}
