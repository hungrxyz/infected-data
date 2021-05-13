//
//  NewHomeAdmissionsCalculator.swift
//  
//
//  Created by marko on 5/8/21.
//

import Foundation

struct NewHomeAdmissionsCalculator {

    let entries: [HomeAdmissionsEntry]

    func callAsFunction() -> Int {
        entries[0].totalActivated.doubled() - entries[1].totalActivated.doubled()
    }

}
