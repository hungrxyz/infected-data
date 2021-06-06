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

    func scrapeVaccinations(calendar: Calendar, completion: @escaping () -> Void) {
        let url = URL(string: "https://coronadashboard.government.nl/landelijk/vaccinaties")!

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            let htmlString = String(decoding: data!, as: UTF8.self)

            let html = try! SwiftSoup.parse(htmlString)

            let vaxDiv = try? html.body()?.getElementsByClass("kpi-value__StyledValue-sc-8puhi4-0 dRYYBv")

            let vaxNumberString = try? vaxDiv?.text().components(separatedBy: " ")[1].components(separatedBy: ",").joined()

            let vaxNumber = vaxNumberString.flatMap(Int.init)

            guard let vaxNumber = vaxNumber else {
                completion()
                return
            }

            let vaccinations = Vaccinations()

            var vaccinationEntries = try! vaccinations.administered()
            let lastEntry = vaccinationEntries.last!

            // Current vax number should be larger than last one.
            // Otherwise there's no need to update.
            guard vaxNumber > lastEntry.doses else {
                completion()
                return
            }

            let date = calendar.startOfDay(for: Date())
            let newEntry = VaccinationsEntry(date: date,
                                             doses: vaxNumber,
                                             dosage: lastEntry.dosage)

            vaccinationEntries.append(newEntry)

            try! vaccinations.update(entries: vaccinationEntries)

            completion()
        }.resume()

    }

}
