//
//  CBSAreaProvider.swift
//  
//
//  Created by marko on 12/7/20.
//

import Foundation
import CodableCSV

final class CBSAreaProvider {

    func areas() throws -> [CBSArea] {
        var configuration = CSVDecoder.Configuration()
        configuration.delimiters.field = ";"
        configuration.delimiters.row = "\r\n"
        configuration.headerStrategy = .firstLine

        let decoder = CSVDecoder(configuration: configuration)

        let fileManager = FileManager.default

        let filename = "Gebieden_in_Nederland_2020_07122020_202646.csv"
        let fileURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
            .appendingPathComponent(filename)

        let fileData = try Data(contentsOf: fileURL)

        let areas = try decoder.decode([CBSArea].self, from: fileData)

        return areas
    }

}
