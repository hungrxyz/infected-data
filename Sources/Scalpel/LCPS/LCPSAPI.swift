//
//  File.swift
//  
//
//  Created by marko on 12/13/20.
//

import Foundation
import CodableCSV

final class LCPSAPI {

    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func entries(completion: @escaping (Result<[LCPSEntry], Error>) -> Void) {
        let url = URL(string: "https://lcps.nu/wp-content/uploads/covid-19.csv")!

        urlSession.dataTask(with: url) { (data, response, error) in

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy"

            var configuration = CSVDecoder.Configuration()
            configuration.delimiters.field = ","
            configuration.delimiters.row = "\n"
            configuration.headerStrategy = .firstLine
            configuration.dateStrategy = .formatted(dateFormatter)

            let decoder = CSVDecoder(configuration: configuration)

            let entries = try! decoder.decode([LCPSEntry].self, from: data!)

            completion(.success(entries))
        }.resume()

    }

}
