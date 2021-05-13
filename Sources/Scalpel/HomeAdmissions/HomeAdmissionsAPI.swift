//
//  File.swift
//  
//
//  Created by marko on 5/13/21.
//

import Foundation

struct HomeAdmissionsAPI {

    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func admissions(completion: @escaping (Result<[HomeAdmissionsEntry], Error>) -> Void) {
        let environment = ProcessInfo.processInfo.environment
        let sessionDTO = MetabaseSessionDTO(
            username: environment["METABASE_USERNAME"]!,
            password: environment["METABASE_PASSWORD"]!
        )

        let sessionURL = URL(string: "https://bi.luscii.com/api/session")!
        var sessionRequest = URLRequest(url: sessionURL)
        sessionRequest.httpMethod = "POST"
        sessionRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        sessionRequest.httpBody = try! JSONEncoder().encode(sessionDTO)
        
        urlSession.dataTask(with: sessionRequest) { sessionData, _, _ in
            let session = try! JSONDecoder().decode(MetabaseSession.self, from: sessionData!)

            let cardURL = URL(string: "https://bi.luscii.com/api/card/1162/query/json")!
            var cardRequest = URLRequest(url: cardURL)
            cardRequest.httpMethod = "POST"
            cardRequest.addValue(session.id, forHTTPHeaderField: "X-Metabase-Session")

            urlSession.dataTask(with: cardRequest) { data, _, _ in
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let entries = try! decoder.decode([HomeAdmissionsEntry].self, from: data!)

                completion(.success(entries))
            }.resume()

        }.resume()
    }

}

private extension HomeAdmissionsAPI {

    struct MetabaseSessionDTO: Encodable {

        let username: String
        let password: String

    }

    struct MetabaseSession: Decodable {

        let id: String

    }

}
