//
//  LCPSEntry.swift
//  
//
//  Created by marko on 12/13/20.
//

import Foundation

struct LCPSEntry {

    let date: Date
    let intensiveCareCOVIDOccupancy: Int?
    let clinicCOVIDOccupancy: Int?

}

extension LCPSEntry: Decodable {

    enum CodingKeys: String, CodingKey {

        case date = "Datum"
        case intensiveCareCOVIDOccupancy = "IC_Bedden_COVID"
        case clinicCOVIDOccupancy = "Kliniek_Bedden"

    }

}
