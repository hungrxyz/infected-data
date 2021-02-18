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
    let vaccinations: SummaryNumbers?

}

struct SummaryNumbers: Encodable {

    let new: Int?
    let trend: Int?
    let total: Int?
    let per100KInhabitants: Float?
    let percentageOfPopulation: Float?

}

struct Occupancy: Encodable {

    let newAdmissions: Int?
    let newAdmissionsTrend: Int?
    let newAdmissionsPer100KInhabitants: Float?
    let currentlyOccupied: Int?
    let currentlyOccupiedTrend: Int?

}
