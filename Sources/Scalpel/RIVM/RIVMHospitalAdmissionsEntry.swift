//
//  RIVMHospitalAdmissionsEntry.swift
//  
//
//  Created by marko on 12/23/20.
//

import Foundation

struct RIVMHospitalAdmissionsEntry {

    let dateOfStatistics: Date
    let municipalityCode: String?
    let securityRegionCode: String?
    let hospitalAdmissionNotification: Int?
    let hospitalAdmission: Int?

}

extension RIVMHospitalAdmissionsEntry: Decodable {

    enum CodingKeys: String, CodingKey {
        case dateOfStatistics = "Date_of_statistics"
        case municipalityCode = "Municipality_code"
        case securityRegionCode = "Security_region_code"
        case hospitalAdmissionNotification = "Hospital_admission_notification"
        case hospitalAdmission = "Hospital_admission"
    }

}

extension RIVMHospitalAdmissionsEntry: Entry {

    var date: Date {
        dateOfStatistics
    }

}
