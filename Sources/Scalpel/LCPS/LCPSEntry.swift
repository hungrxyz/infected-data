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
        case intensiveCareCOVIDOccupancy = "IC_Bedden_COVID_Nederland"
        case clinicCOVIDOccupancy = "Kliniek_Bedden_Nederland"

    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        date = try container.decode(Date.self, forKey: .date)
        intensiveCareCOVIDOccupancy = try? container.decode(Int.self, forKey: .intensiveCareCOVIDOccupancy)
        clinicCOVIDOccupancy = try? container.decode(Int.self, forKey: .clinicCOVIDOccupancy)
    }

}
