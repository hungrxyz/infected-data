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
        let totalAdministeredPerEffectiveness = Float(entry.doses) * entry.effectiveness

        return totalAdministeredPerEffectiveness / Float(population)
    }

}
