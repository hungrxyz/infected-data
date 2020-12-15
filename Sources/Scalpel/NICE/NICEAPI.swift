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
        let url = URL(string: "https://luscii-infected-data.s3.eu-central-1.amazonaws.com/nice_hospital_new_intakes.json")!

        urlSession.dataTask(with: url) { (data, response, error) in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let entries = try! Self.jsonDecoder.decode([NICEEntry].self, from: data!)

            completion(.success(entries))
        }.resume()

    }

    func dailyIntensiveCareAddmissions(completion: @escaping (Result<[NICEEntry], Error>) -> Void) {
        let url = URL(string: "https://luscii-infected-data.s3.eu-central-1.amazonaws.com/nice_intensive_care_new_intakes.json")!

        urlSession.dataTask(with: url) { (data, response, error) in

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let entries = try! Self.jsonDecoder.decode([NICEEntry].self, from: data!)

            completion(.success(entries))
        }.resume()

    }

}
