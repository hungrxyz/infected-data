//
//  HomeAdmissions.swift
//  
//
//  Created by marko on 5/8/21.
//

import Foundation
import CodableCSV

struct HomeAdmissions {

    func entries() throws -> [HomeAdmissionsEntry] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var configuration = CSVDecoder.Configuration()
        configuration.delimiters.field = ","
        configuration.headerStrategy = .firstLine
        configuration.dateStrategy = .formatted(dateFormatter)

        let decoder = CSVDecoder(configuration: configuration)

        let fileURL = Bundle.module.url(forResource: "luscii_home_admissions", withExtension: "csv")!
        let fileData = try Data(contentsOf: fileURL)

        return try decoder.decode([HomeAdmissionsEntry].self, from: fileData)
    }

}
