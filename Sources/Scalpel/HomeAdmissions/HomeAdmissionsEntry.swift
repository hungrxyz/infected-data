//
//  HomeAdmissionsEntry.swift
//  
//
//  Created by marko on 5/8/21.
//

import Foundation

struct HomeAdmissionsEntry {

    let totalActivated: Int
    let totalStopped: Int
    let currentlyActive: Int

}

extension HomeAdmissionsEntry: Decodable {
}
