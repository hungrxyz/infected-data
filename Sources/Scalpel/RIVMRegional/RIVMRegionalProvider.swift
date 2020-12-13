//
//  RIVMRegionalProvider.swift
//  
//
//  Created by marko on 12/12/20.
//

import Foundation
import CodableCSV

final class RIVMRegionalProvider {

    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func regional(completion: @escaping (Result<RIVMRegional, Error>) -> Void) {
        let url = URL(string: "https://data.rivm.nl/covid-19/COVID-19_aantallen_gemeente_per_dag.csv")!

        urlSession.dataTask(with: url) { (data, response, error) in

            let lastModified = response?.lastModified

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            var configuration = CSVDecoder.Configuration()
            configuration.delimiters.field = ";"
            configuration.delimiters.row = "\r\n"
            configuration.headerStrategy = .firstLine
            configuration.dateStrategy = .formatted(dateFormatter)

            let decoder = CSVDecoder(configuration: configuration)

            let entries = try! decoder.decode([RIVMRegionalEntry].self, from: data!)

            completion(.success(RIVMRegional(lastModified: lastModified!, entries: entries)))
        }.resume()

    }

}

private extension URLResponse {

    var lastModified: Date? {
        let lastModifiedDateFormatter = DateFormatter()
        lastModifiedDateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"

        guard
            let httpResponse = self as? HTTPURLResponse,
            let lastModifiedHeaderValue = httpResponse.allHeaderFields["Last-Modified"] as? String
        else {
            return nil
        }

        return lastModifiedDateFormatter.date(from: lastModifiedHeaderValue)
    }

}
