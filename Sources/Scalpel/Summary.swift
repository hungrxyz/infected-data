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
    let hospitalOccupancy: Occupancy?
    let intensiveCareOccupancy: Occupancy?
    let deaths: SummaryNumbers

}

struct SummaryNumbers: Encodable {

    let new: Int?
    let trend: Int?
    let total: Int?

}

struct Occupancy: Encodable {

    let newAdmissions: Int?
    let newAdmissionsTrend: Int?
    let currentlyOccupied: Int?
    let currentlyOccupiedTrend: Int?

}
