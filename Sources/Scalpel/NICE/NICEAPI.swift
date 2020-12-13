//
//  File.swift
//  
//
//  Created by marko on 12/13/20.
//

import Foundation

final class NICEAPI {

    private static var jsonDecoder: JSONDecoder = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        return decoder
    }()

    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func dailyHospitalAdmissions(completion: @escaping (Result<[NICEEntry], Error>) -> Void) {
        let url = URL(string: "https://stichting-nice.nl/covid-19/public/zkh/new-intake/confirmed")!

        urlSession.dataTask(with: url) { (data, response, error) in
            print(response)
            let entries = try! Self.jsonDecoder.decode([NICEEntry].self, from: data!)

            completion(.success(entries))
        }.resume()

    }

    func dailyIntensiveCareAddmissions(completion: @escaping (Result<[NICEEntry], Error>) -> Void) {
        let url = URL(string: "https://stichting-nice.nl/covid-19/public/new-intake/confirmed")!

        urlSession.dataTask(with: url) { (data, response, error) in
            print(response)
            let entries = try! Self.jsonDecoder.decode([NICEEntry].self, from: data!)

            completion(.success(entries))
        }.resume()

    }

}
