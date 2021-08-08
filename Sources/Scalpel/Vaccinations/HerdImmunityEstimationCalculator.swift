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
        let latestEntry = vaccinationEntries.last!
        let fullyVaxxedPeople = Int(Float(latestEntry.doses) * latestEntry.fullyVaxxedPercentage)
        let totalAdministeredGoal = population

        // 70% of population
        let herdImmunityThreshold = Int(Float(totalAdministeredGoal) * 0.7)

        // Averages per quarter
        var averageDeliveriesPerWeek = [Date: Int]()
        for deliveryEntry in vaccinationDeliveries {
            let daysInAWeek = 7
            let perPerson = Int(Float(deliveryEntry.doses) * deliveryEntry.dosage)
            let average = perPerson / daysInAWeek

            averageDeliveriesPerWeek[deliveryEntry.date] = average
        }

        let todayStartOfDay = calendar.startOfDay(for: Date())

        var daysToGo = 0
        var dayByDay = fullyVaxxedPeople
        var lastKnownWeekStartDate: Date!

        let enumarationDateComponents = DateComponents(hour: 0, minute: 0, second: 0)
        calendar.enumerateDates(startingAfter: todayStartOfDay, matching: enumarationDateComponents, matchingPolicy: .nextTime) { (date, _, shouldStop) in
            let weekStartDate = calendar.startOfWeek(for: date!)

            let averagePerDay: Int
            if let knownAveragePerDay = averageDeliveriesPerWeek[weekStartDate] {
                averagePerDay = knownAveragePerDay
                lastKnownWeekStartDate = weekStartDate
            } else {
                averagePerDay = averageDeliveriesPerWeek[lastKnownWeekStartDate]!
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

    func startOfWeek(for date: Date) -> Date {
        dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: date).date!
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
