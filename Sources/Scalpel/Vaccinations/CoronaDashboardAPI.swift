//
//  CoronaDashboardAPI.swift
//  
//
//  Created by marko on 6/6/21.
//

import Foundation
import SwiftSoup
import CodableCSV

struct CoronaDashboardAPI {

    func scrapeVaccinations(calendar: Calendar, completion: @escaping ([VaccinationsEntry]?) -> Void) {
        let url = URL(string: "https://coronadashboard.government.nl/landelijk/vaccinaties")!

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            let htmlString = String(decoding: data!, as: UTF8.self)

            let html = try! SwiftSoup.parse(htmlString)

            let vaxDiv = try? html.body()?.getElementsByClass("sc-8puhi4-0 qJICb")

            let vaxDivComponents = try? vaxDiv?.text().components(separatedBy: " ")

            guard (vaxDivComponents?.count ?? 0) >= 4 else {
                completion(nil)
                return
            }

            let vaxNumberString = vaxDivComponents?[3].components(separatedBy: ",").joined()

            guard let vaxNumber = vaxNumberString.flatMap(Int.init) else {
                completion(nil)
                return
            }

            let vaccinations = Vaccinations()

            var vaccinationEntries = try! vaccinations.administered()
            let lastEntry = vaccinationEntries.last!

            // Current vax number should be larger than last one.
            // Otherwise there's no need to update.
            guard vaxNumber > lastEntry.doses else {
                completion(nil)
                return
            }

            let date = calendar.startOfDay(for: Date())
            let newEntry = VaccinationsEntry(date: date,
                                             doses: vaxNumber,
                                             dosage: lastEntry.dosage,
                                             fullyVaxxedPercentage: lastEntry.fullyVaxxedPercentage)

            vaccinationEntries.append(newEntry)

            try! vaccinations.update(entries: vaccinationEntries)

            completion(vaccinationEntries)
        }.resume()

    }

}
