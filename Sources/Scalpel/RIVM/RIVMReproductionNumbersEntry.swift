//
//  File.swift
//  
//
//  Created by marko on 5/1/21.
//

import Foundation

struct RIVMReproductionNumbersEntry {

    let average: Float?

}

extension RIVMReproductionNumbersEntry: Decodable {

    enum CodingKeys: String, CodingKey {
        case average = "Rt_avg"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        average = try container.decodeIfPresent(String.self, forKey: .average).flatMap(Float.init)
    }

}
