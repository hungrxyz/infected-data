//
//  RIVMRegionalEntry.swift
//  
//
//  Created by marko on 11/25/20.
//

import Foundation

struct RIVMRegionalEntry: Decodable {

    let dateOfPublication: Date
    let municipalityCode: String?
    let municipalityName: String?
    let provinceName: String?
    let securityRegionCode: String?
    let securityRegionName: String?
    let totalReported: Int?
    let hospitalAdmissions: Int?
    let deceased: Int?

    enum CodingKeys: String, CodingKey {

        case dateOfPublication = "Date_of_publication"
        case municipalityCode = "Municipality_code"
        case municipalityName = "Municipality_name"
        case provinceName = "Province"
        case securityRegionCode = "Security_region_code"
        case securityRegionName = "Security_region_name"
        case totalReported = "Total_reported"
        case hospitalAdmissions = "Hospital_admission"
        case deceased = "Deceased"

    }

}
