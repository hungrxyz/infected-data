//
//  RIVMAPI.swift
//  
//
//  Created by marko on 12/12/20.
//

import Foundation
import CodableCSV

final class RIVMAPI {

    private static let csvDecoder: CSVDecoder = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var configuration = CSVDecoder.Configuration()
        configuration.delimiters.field = ";"
        configuration.delimiters.row = "\r\n"
        configuration.headerStrategy = .firstLine
        configuration.dateStrategy = .formatted(dateFormatter)

        let decoder = CSVDecoder(configuration: configuration)

        return decoder
    }()

    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func regional(completion: @escaping (Result<RIVMRegional, Error>) -> Void) {
        let url = URL(string: "https://data.rivm.nl/covid-19/COVID-19_aantallen_gemeente_per_dag.csv")!

        urlSession.dataTask(with: url) { (data, response, error) in
            let entries = try! Self.csvDecoder.decode([RIVMRegionalEntry].self, from: data!)

            completion(.success(RIVMRegional(lastModified: Date(), entries: entries)))
        }.resume()

    }

    func hospitalAdmissions(completion: @escaping (Result<[RIVMHospitalAdmissionsEntry], Error>) -> Void) {
        let url = URL(string: "https://data.rivm.nl/covid-19/COVID-19_ziekenhuisopnames.csv")!

        urlSession.dataTask(with: url) { (data, response, error) in
            let entries = try! Self.csvDecoder.decode([RIVMHospitalAdmissionsEntry].self, from: data!)

            completion(.success(entries))
        }.resume()

    }

}
