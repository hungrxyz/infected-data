//
//  VaccionationCoverageCalculator.swift
//  
//
//  Created by marko on 2/28/21.
//

import Foundation

struct VaccionationCoverageCalculator {

    let totalAdministered: Int
    let population: Int

    func callAsFunction() -> Float {
        // Double population since all vaccines currently require 2 shots
        let doublePopulation = population * 2

        return Float(totalAdministered) / Float(doublePopulation)
    }

}
