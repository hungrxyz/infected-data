//
//  GroupedRegionsDTO.swift
//  
//
//  Created by marko on 11/26/20.
//

import Foundation

struct GroupedRegionsDTO: Encodable {

    let updatedAt: Date
    let numbersDate: Date
    let regions: [Summary]

}
