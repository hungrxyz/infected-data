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
    let homeAdmissions: Occupancy?
    let deaths: SummaryNumbers
    let vaccinations: VaccinationsSummary?

}

struct SummaryNumbers: Encodable {

    let new: Int?
    let trend: Int?
    let total: Int?
    let average: Int?
    let per100KInhabitants: Float?
    let percentageOfPopulation: Float?

}

struct Occupancy: Encodable {

    let newAdmissions: Int?
    let newAdmissionsTrend: Int?
    let newAdmissionsPer100KInhabitants: Float?
    let currentlyOccupied: Int?
    let currentlyOccupiedTrend: Int?
    let currentlyOccupiedPer100KInhabitants: Float?

}

struct VaccinationsSummary: Encodable {

    let numbers: SummaryNumbers
    let herdImmunityCurrentTrendDate: Date
    let herdImmunityEstimatedDate: Date
    let lastUpdated: Date

    // For backwards compatibilility, to be removed after some months.
    let new: Int?
    let trend: Int?
    let total: Int?
    let average: Int?
    let per100KInhabitants: Float?
    let percentageOfPopulation: Float?

}
