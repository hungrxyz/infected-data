//
//  NewVaccinationsCalculator.swift
//  
//
//  Created by marko on 2/28/21.
//

import Foundation

struct NewVaccinationsCalculator {

    let entries: [VaccinationsEntry]

    func callAsFunction() -> Int {
        var _entries = entries

        guard
            let current = _entries.popLast(),
            let previous = _entries.popLast()
        else {
            fatalError("Mmmm okay, no vaccionation entries present")
        }

        return current.administered - previous.administered
    }

}
