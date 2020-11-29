//
//  NumbersAccumulator.swift
//  
//
//  Created by marko on 11/29/20.
//

import Foundation

typealias AccumulatedNumbers = (positiveCases: Int, hospitalAdmissions: Int, deaths: Int)

final class NumbersAccumulator {

    func accumulate(entries: [RIVMRegionalEntry]) -> AccumulatedNumbers {
        entries.reduce(into: (0, 0, 0), { (result, entry) in
            result.0 += entry.totalReported ?? 0
            result.1 += entry.hospitalAdmissions ?? 0
            result.2 += entry.deceased ?? 0
        })
    }

}
