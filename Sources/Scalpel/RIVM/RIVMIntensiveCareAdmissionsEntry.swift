//
//  File.swift
//  
//
//  Created by marko on 5/1/21.
//

import Foundation

struct RIVMIntensiveCareAdmissionsEntry {

    let dateOfStatistics: Date
    let icAdmissionNotification: Int?
    let icAdmission: Int?

}

extension RIVMIntensiveCareAdmissionsEntry: Decodable {

    enum CodingKeys: String, CodingKey {
        case dateOfStatistics = "Date_of_statistics"
        case icAdmissionNotification = "IC_admission_notification"
        case icAdmission = "IC_admission"
    }

}

extension RIVMIntensiveCareAdmissionsEntry: Entry {

    var date: Date {
        dateOfStatistics
    }

}
