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

    func update(entries: [VaccinationsEntry]) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var configuration = CSVEncoder.Configuration()
        configuration.delimiters.field = ","
        configuration.headers = ["date", "doses", "dosage", "fullyVaxxedPercentage"]
        configuration.dateStrategy = .formatted(dateFormatter)

        let encoder = CSVEncoder(configuration: configuration)

        let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources")
            .appendingPathComponent("Scalpel")
            .appendingPathComponent("Vaccinations")
            .appendingPathComponent("vaccinations_administered.csv")

        try encoder.encode(entries, into: fileURL)
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
