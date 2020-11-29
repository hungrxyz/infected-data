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

        let positiveCasesNumbers = SummaryNumbers(
            new: todayCounts.positiveCases,
            trend: trend(today: todayCounts.positiveCases, yesterday: yesterdaysCounts.positiveCases),
            total: totalCounts.positiveCases
        )

        let hospitalAdmissionsNumbers = SummaryNumbers(
            new: todayCounts.hospitalAdmissions,
            trend: trend(today: todayCounts.hospitalAdmissions, yesterday: yesterdaysCounts.hospitalAdmissions),
            total: totalCounts.hospitalAdmissions
        )

        let deathNumbers = SummaryNumbers(
            new: todayCounts.deaths,
            trend: trend(today: todayCounts.deaths, yesterday: yesterdaysCounts.deaths),
            total: totalCounts.deaths
        )

        guard let updatedAt = lastModified, let numbersDate = todaysEntries.first?.dateOfPublication else {
            fatalError("Missing todays entries dates")
        }

        let summary = Summary(updatedAt: updatedAt,
                              numbersDate: numbersDate,
                              regionCode: "NL00",
                              municupalityName: nil,
                              provinceName: nil,
                              securityRegionName: nil,
                              positiveCases: positiveCasesNumbers,
                              hospitalAdmissions: hospitalAdmissionsNumbers,
                              deaths: deathNumbers)

        let encoder = JSONEncoder()
        if #available(OSX 10.15, *) {
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
        }

        let summaryJSON = try encoder.encode(summary)

        let latestURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("data")
            .appendingPathComponent("rivm")
            .appendingPathComponent("latest")

        let regionURL = latestURL.appendingPathComponent("region")

        try FileManager.default.createDirectory(at: regionURL, withIntermediateDirectories: true)

        let nationalURL = latestURL.appendingPathComponent("national.json")

        FileManager.default.createFile(atPath: nationalURL.path, contents: summaryJSON)

        // MARK: - Municipal

        var municipalSummaries = [Summary]()

        let municipalEntries = todaysEntries.filter { $0.municipalityCode != nil }

        for entry in municipalEntries {

            let regionCode = entry.municipalityCode!

            let totalsEntries = allEntries.filter { $0.municipalityCode == regionCode }
            let totals = accumulator.accumulate(entries: totalsEntries)

            let todaysEntry = todaysEntries.first { $0.municipalityCode == regionCode }
            let yesterdaysEntry = yesterdaysEntries.first { $0.municipalityCode == regionCode }

            let positiveCases = SummaryNumbers(
                new: todaysEntry?.totalReported,
                trend: trend(today: todaysEntry?.totalReported, yesterday: yesterdaysEntry?.totalReported),
                total: totals.positiveCases
            )

            let hospitalAdmissions = SummaryNumbers(
                new: todaysEntry?.hospitalAdmissions,
                trend: trend(today: todaysEntry?.hospitalAdmissions, yesterday: yesterdaysEntry?.hospitalAdmissions),
                total: totals.hospitalAdmissions
            )

            let deaths = SummaryNumbers(
                new: todaysEntry?.deceased,
                trend: trend(today: todaysEntry?.deceased, yesterday: yesterdaysEntry?.deceased),
                total: totals.deaths
            )

            let summary = Summary(
                updatedAt: updatedAt,
                numbersDate: numbersDate,
                regionCode: regionCode,
                municupalityName: entry.municipalityName,
                provinceName: entry.provinceName,
                securityRegionName: entry.securityRegionName,
                positiveCases: positiveCases,
                hospitalAdmissions: hospitalAdmissions,
                deaths: deaths
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

            let positiveCases = SummaryNumbers(
                new: todaysNumbers.positiveCases,
                trend: trend(today: todaysNumbers.positiveCases, yesterday: yesterdaysNumbers.positiveCases),
                total: totals.positiveCases
            )

            let hospitalAdmissions = SummaryNumbers(
                new: todaysNumbers.hospitalAdmissions,
                trend: trend(today: todaysNumbers.hospitalAdmissions, yesterday: yesterdaysNumbers.hospitalAdmissions),
                total: totals.hospitalAdmissions
            )

            let deaths = SummaryNumbers(
                new: todaysNumbers.deaths,
                trend: trend(today: todaysNumbers.deaths, yesterday: yesterdaysNumbers.deaths),
                total: totals.deaths
            )

            let summary = Summary(
                updatedAt: updatedAt,
                numbersDate: numbersDate,
                regionCode: regionCode,
                municupalityName: entry.municipalityName,
                provinceName: entry.provinceName,
                securityRegionName: entry.securityRegionName,
                positiveCases: positiveCases,
                hospitalAdmissions: hospitalAdmissions,
                deaths: deaths
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

    }

    func trend(today: Int?, yesterday: Int?) -> Int? {
        guard let today = today, let yesterday = yesterday else {
            return nil
        }
        return today - yesterday
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
