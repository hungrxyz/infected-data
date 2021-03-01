//
//  Vaccinations.swift
//  
//
//  Created by marko on 2/28/21.
//

import Foundation
import CodableCSV

struct Vaccinations {

    func callAsFunction() throws -> [VaccinationsEntry] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var configuration = CSVDecoder.Configuration()
        configuration.delimiters.field = ","
        configuration.headerStrategy = .firstLine
        configuration.dateStrategy = .formatted(dateFormatter)

        let decoder = CSVDecoder(configuration: configuration)

        let fileURL = Bundle.module.url(forResource: "vaccinations", withExtension: "csv")!
        let fileData = try Data(contentsOf: fileURL)

        let areas = try decoder.decode([VaccinationsEntry].self, from: fileData)

        return areas
    }

}
