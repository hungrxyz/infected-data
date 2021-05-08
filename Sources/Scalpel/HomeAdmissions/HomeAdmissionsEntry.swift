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

}

extension HomeAdmissionsEntry: Decodable {
}
