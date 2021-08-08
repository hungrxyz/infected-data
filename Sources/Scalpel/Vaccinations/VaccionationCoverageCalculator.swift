//
//  VaccionationCoverageCalculator.swift
//  
//
//  Created by marko on 2/28/21.
//

import Foundation

struct VaccionationCoverageCalculator {

    let entry: VaccinationsEntry
    let population: Int

    func callAsFunction() -> Float {
        let fullyVaxxedDoses = Float(entry.doses) * entry.fullyVaxxedPercentage

        return fullyVaxxedDoses / Float(population)
    }

}
