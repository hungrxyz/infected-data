//
//  ActiveHomeAdmissionsCalculator.swift
//  
//
//  Created by marko on 5/8/21.
//

import Foundation

struct ActiveHomeAdmissionsCalculator {

    let entry: HomeAdmissionsEntry

    func callAsFunction() -> Int {
        entry.totalActivated - entry.totalStopped
    }

}
