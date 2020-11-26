//
//  Summary.swift
//  
//
//  Created by marko on 11/25/20.
//

import Foundation

struct Summary: Encodable {

    let updatedAt: Date?
    let numbersDate: Date?
    let regionCode: String?
    let municupalityName: String?
    let provinceName: String?
    let securityRegionName: String?
    let positiveCases: SummaryNumbers
    let hospitalAdmissions: SummaryNumbers
    let deaths: SummaryNumbers

}

struct SummaryNumbers: Encodable {

    let new: Int?
    let trend: Int?
    let total: Int?

}
