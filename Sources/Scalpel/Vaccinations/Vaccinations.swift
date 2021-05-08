//
//  Vaccinations.swift
//  
//
//  Created by marko on 2/28/21.
//

import Foundation
import CodableCSV

struct Vaccinations {

    func administered() throws -> [VaccinationsEntry] {
        try entries(resourceName: "vaccinations_administered")
    }

    func deliveries() throws -> [VaccinationsEntry] {
        try entries(resourceName: "vaccinations_deliveries")
    }

    private func entries(resourceName: String) throws -> [VaccinationsEntry] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var configuration = CSVDecoder.Configuration()
        configuration.delimiters.field = ","
        configuration.headerStrategy = .firstLine
        configuration.dateStrategy = .formatted(dateFormatter)

        let decoder = CSVDecoder(configuration: configuration)

        let fileURL = Bundle.module.url(forResource: resourceName, withExtension: "csv")!
        let fileData = try Data(contentsOf: fileURL)

        return try decoder.decode([VaccinationsEntry].self, from: fileData)
    }

}
