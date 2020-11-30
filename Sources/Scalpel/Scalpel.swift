//
//  Scalpel.swift
//  
//
//  Created by marko on 11/22/20.
//

import Foundation
import ArgumentParser
import CodableCSV

struct Scalpel: ParsableCommand {

    func run() throws {

        let semaphore = DispatchSemaphore(value: 0)

        var lastModified: Date!
        var allEntries: [RIVMRegionalEntry]!

        let url = URL(string: "https://data.rivm.nl/covid-19/COVID-19_aantallen_gemeente_per_dag.csv")!

        URLSession.shared.dataTask(with: url) { (data, response, error) in

            lastModified = response?.lastModified

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            var configuration = CSVDecoder.Configuration()
            configuration.delimiters.field = ";"
            configuration.delimiters.row = "\r\n"
            configuration.headerStrategy = .firstLine
            configuration.dateStrategy = .formatted(dateFormatter)

            let decoder = CSVDecoder(configuration: configuration)

            let entries = try! decoder.decode([RIVMRegionalEntry].self, from: data!)

            allEntries = entries

            semaphore.signal()
        }.resume()

        semaphore.wait()

        let accumulator = NumbersAccumulator()
        let calendar = Calendar(identifier: .iso8601)

        // MARK: - National

        let totalCounts = accumulator.accumulate(entries: allEntries)

        let todaysEntries = allEntries.filter { calendar.isDateInToday($0.dateOfPublication) }
        let todayCounts = accumulator.accumulate(entries: todaysEntries)

        let yesterdaysEntries = allEntries.filter { calendar.isDateInYesterday($0.dateOfPublication) }
        let yesterdaysCounts = accumulator.accumulate(entries: yesterdaysEntries)

        guard let updatedAt = lastModified, let numbersDate = todaysEntries.first?.dateOfPublication else {
            fatalError("Missing todays entries dates")
        }

        let summarizedNumbers = summarizeEntries(today: todayCounts,
                                                 yesterday: yesterdaysCounts,
                                                 total: totalCounts)

        let summary = Summary(updatedAt: updatedAt,
                              numbersDate: numbersDate,
                              regionCode: "NL00",
                              municupalityName: nil,
                              provinceName: nil,
                              securityRegionName: nil,
                              positiveCases: summarizedNumbers.positiveCases,
                              hospitalAdmissions: summarizedNumbers.hospitalAdmissions,
                              deaths: summarizedNumbers.deaths)

        let encoder = JSONEncoder()
        if #available(OSX 10.15, *) {
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
        }

        let summaryJSON = try encoder.encode(summary)

        let latestURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("data")
            .appendingPathComponent("latest")

        let regionURL = latestURL.appendingPathComponent("region")

        try FileManager.default.createDirectory(at: regionURL, withIntermediateDirectories: true)

        let nationalURL = latestURL.appendingPathComponent("national.json")

        FileManager.default.createFile(atPath: nationalURL.path, contents: summaryJSON)

        // MARK: - Municipalities

        var municipalSummaries = [Summary]()

        let municipalEntries = todaysEntries.filter { $0.municipalityCode != nil }

        for entry in municipalEntries {

            let regionCode = entry.municipalityCode!

            let totalsEntries = allEntries.filter { $0.municipalityCode == regionCode }
            let totals = accumulator.accumulate(entries: totalsEntries)

            guard
                let todaysEntry = todaysEntries.first(where: { $0.municipalityCode == regionCode }),
                let yesterdaysEntry = yesterdaysEntries.first(where: { $0.municipalityCode == regionCode })
            else {
                continue
            }

            let summarizedNumbers = summarizeEntries(today: todaysEntry.accumulatedNumbers,
                                                     yesterday: yesterdaysEntry.accumulatedNumbers,
                                                     total: totals)

            let summary = Summary(
                updatedAt: updatedAt,
                numbersDate: numbersDate,
                regionCode: regionCode,
                municupalityName: entry.municipalityName,
                provinceName: entry.provinceName,
                securityRegionName: entry.securityRegionName,
                positiveCases: summarizedNumbers.positiveCases,
                hospitalAdmissions: summarizedNumbers.hospitalAdmissions,
                deaths: summarizedNumbers.deaths
            )

            let json = try encoder.encode(summary)

            let filename = [regionCode, "json"].joined(separator: ".")
            let fileURL = regionURL.appendingPathComponent(filename)

            FileManager.default.createFile(atPath: fileURL.path, contents: json, attributes: nil)

            municipalSummaries.append(summary)
        }

        let allMunicipalitiesDTO = GroupedRegionsDTO(
            updatedAt: updatedAt,
            numbersDate: numbersDate,
            regions: municipalSummaries.map { $0.nillifyingDates() }
        )

        let allMunicipalitiesJSON = try encoder.encode(allMunicipalitiesDTO)

        let allMunicipalitiesURL = latestURL.appendingPathComponent("municipalities.json")

        FileManager.default.createFile(atPath: allMunicipalitiesURL.path, contents: allMunicipalitiesJSON)

        // MARK: - Security Regions

        var securityRegionsSummaries = [Summary]()

        let securityRegionEntries = todaysEntries.filter { $0.municipalityCode == nil }

        for entry in securityRegionEntries {

            let regionCode = entry.securityRegionCode ?? "XX00"

            let totalsEntries = allEntries.filter { $0.securityRegionCode == regionCode }
            let totals = accumulator.accumulate(entries: totalsEntries)

            let todaysEntriesForSecurityRegion = todaysEntries.filter { $0.securityRegionCode == regionCode }
            let todaysNumbers = accumulator.accumulate(entries: todaysEntriesForSecurityRegion)

            let yesterdaysEntriesForSecurityRegion = yesterdaysEntries.filter { $0.securityRegionCode == regionCode }
            let yesterdaysNumbers = accumulator.accumulate(entries: yesterdaysEntriesForSecurityRegion)

            let summarizedNumbers = summarizeEntries(today: todaysNumbers, yesterday: yesterdaysNumbers, total: totals)

            let summary = Summary(
                updatedAt: updatedAt,
                numbersDate: numbersDate,
                regionCode: regionCode,
                municupalityName: entry.municipalityName,
                provinceName: entry.provinceName,
                securityRegionName: entry.securityRegionName,
                positiveCases: summarizedNumbers.positiveCases,
                hospitalAdmissions: summarizedNumbers.hospitalAdmissions,
                deaths: summarizedNumbers.deaths
            )

            let json = try encoder.encode(summary)

            let filename = [regionCode, "json"].joined(separator: ".")
            let fileURL = regionURL.appendingPathComponent(filename)

            FileManager.default.createFile(atPath: fileURL.path, contents: json, attributes: nil)

            securityRegionsSummaries.append(summary)
        }

        let allSecurityRegionsDTO = GroupedRegionsDTO(
            updatedAt: updatedAt,
            numbersDate: numbersDate,
            regions: securityRegionsSummaries.map { $0.nillifyingDates() }
        )

        let allSecurityRegionsJSON = try encoder.encode(allSecurityRegionsDTO)

        let allSecurityRegionsURL = latestURL.appendingPathComponent("security_regions.json")

        FileManager.default.createFile(atPath: allSecurityRegionsURL.path, contents: allSecurityRegionsJSON)

        // MARK: - Provinces

        // Map of province name and ISO 3166-2 codes
        // https://nl.wikipedia.org/wiki/ISO_3166-2:NL
        let provincesNameCodes = [
            "Drenthe": "NL-DR",
            "Flevoland": "NL-FL",
            "Friesland": "NL-FR",
            "Gelderland": "NL-GE",
            "Groningen": "NL-GR",
            "Limburg": "NL-LI",
            "Noord-Brabant": "NL-NB",
            "Noord-Holland": "NL-NH",
            "Overijssel": "NL-OV",
            "Utrecht": "NL-UT",
            "Zeeland": "NL-ZE",
            "Zuid-Holland": "NL-ZH",
            "Bonaire": "NL-BQ1",
            "Saba": "NL-BQ2",
            "Sint Eustatius": "NL-BQ3",
            "Aruba": "NL-AW",
            "Curaçao": "NL-CW",
            "Sint Maarten": "NL-SX"
        ]

        let provinceNames = Array(provincesNameCodes.keys).sorted()

        var provincesSummaries = [Summary]()

        for provinceName in provinceNames {

            let regionCode = provincesNameCodes[provinceName]!

            let totalsEntries = allEntries.filter { $0.provinceName == provinceName }
            let totals = accumulator.accumulate(entries: totalsEntries)

            let todaysProvincialEntries = todaysEntries.filter { $0.provinceName == provinceName }
            let todaysNumbers = accumulator.accumulate(entries: todaysProvincialEntries)

            let yesterdaysProvincialEntries = yesterdaysEntries.filter { $0.provinceName == provinceName }
            let yesterdaysNumbers = accumulator.accumulate(entries: yesterdaysProvincialEntries)

            // Early exit in case no entries found for province
            if todaysProvincialEntries.isEmpty {
                continue
            }

            let summarizedNumbers = summarizeEntries(today: todaysNumbers, yesterday: yesterdaysNumbers, total: totals)

            let summary = Summary(
                updatedAt: updatedAt,
                numbersDate: numbersDate,
                regionCode: regionCode,
                municupalityName: nil,
                provinceName: provinceName,
                securityRegionName: nil,
                positiveCases: summarizedNumbers.positiveCases,
                hospitalAdmissions: summarizedNumbers.hospitalAdmissions,
                deaths: summarizedNumbers.deaths
            )

            let json = try encoder.encode(summary)

            let filename = [regionCode, "json"].joined(separator: ".")
            let fileURL = regionURL.appendingPathComponent(filename)

            FileManager.default.createFile(atPath: fileURL.path, contents: json, attributes: nil)

            provincesSummaries.append(summary)
        }

        let allProvincesDTO = GroupedRegionsDTO(
            updatedAt: updatedAt,
            numbersDate: numbersDate,
            regions: provincesSummaries.map { $0.nillifyingDates() }
        )

        let allProvincesJSON = try encoder.encode(allProvincesDTO)

        let allProvincesURL = latestURL.appendingPathComponent("provinces.json")

        FileManager.default.createFile(atPath: allProvincesURL.path, contents: allProvincesJSON)

    }

    func trend(today: Int?, yesterday: Int?) -> Int? {
        guard let today = today, let yesterday = yesterday else {
            return nil
        }
        return today - yesterday
    }

    func summarizeEntries(today: AccumulatedNumbers,
                          yesterday: AccumulatedNumbers,
                          total: AccumulatedNumbers) -> (positiveCases: SummaryNumbers, hospitalAdmissions: SummaryNumbers, deaths: SummaryNumbers) {

        let positiveCases = SummaryNumbers(
            new: today.positiveCases,
            trend: trend(today: today.positiveCases, yesterday: yesterday.positiveCases),
            total: total.positiveCases
        )

        let hospitalAdmissions = SummaryNumbers(
            new: today.hospitalAdmissions,
            trend: trend(today: today.hospitalAdmissions, yesterday: yesterday.hospitalAdmissions),
            total: total.hospitalAdmissions
        )

        let deaths = SummaryNumbers(
            new: today.deaths,
            trend: trend(today: today.deaths, yesterday: yesterday.deaths),
            total: total.deaths
        )

        return (positiveCases, hospitalAdmissions, deaths)

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

private extension Summary {

    func nillifyingDates() -> Summary {
        Summary(updatedAt: nil,
                numbersDate: nil,
                regionCode: regionCode,
                municupalityName: municupalityName,
                provinceName: provinceName,
                securityRegionName: securityRegionName,
                positiveCases: positiveCases,
                hospitalAdmissions: hospitalAdmissions,
                deaths: deaths)
    }

}

private extension RIVMRegionalEntry {

    var accumulatedNumbers: AccumulatedNumbers {
        (totalReported ?? 0, hospitalAdmissions ?? 0, deceased ?? 0)
    }

}
