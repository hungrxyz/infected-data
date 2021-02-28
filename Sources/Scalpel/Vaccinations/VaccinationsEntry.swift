//
//  VaccinationsEntry.swift
//  
//
//  Created by marko on 2/28/21.
//

import Foundation

struct VaccinationsEntry {

    let date: Date
    let administered: Int

}

extension VaccinationsEntry: Decodable {
}
