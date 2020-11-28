//
//  Scalpel.swift
//  
//
//  Created by marko on 11/22/20.
//

import Foundation
import ArgumentParser
import CodableCSV
import ShellOut

struct Scalpel: ParsableCommand {

    func run() throws {

        let semaphore = DispatchSemaphore(value: 0)

        var lastModified: Date?
        var allEntries: [RIVMRegionalEntry]?
        var todaysEntries: [RIVMRegionalEntry]?
        var yesterdaysEntries: [RIVMRegionalEntry]?

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

            let calendar = Calendar(identifier: .iso8601)

            todaysEntries = entries.filter { calendar.isDateInToday($0.dateOfPublication) }
            yesterdaysEntries = entries.filter { calendar.isDateInYesterday($0.dateOfPublication) }

            semaphore.signal()
        }.resume()

        semaphore.wait()

        let totalCounts = allEntries?
            .reduce(into: (cases: 0, hospitalizations: 0, deaths: 0), { (result, entry) in
                result.cases += entry.totalReported ?? 0
                result.hospitalizations += entry.hospitalAdmissions ?? 0
                result.deaths += entry.deceased ?? 0
            })

        let todayCounts = todaysEntries?
            .reduce(into: (cases: 0, hospitalizations: 0, deaths: 0), { (result, entry) in
                result.cases += entry.totalReported ?? 0
                result.hospitalizations += entry.hospitalAdmissions ?? 0
                result.deaths += entry.deceased ?? 0
            })

        let yesterdaysCounts = yesterdaysEntries?
            .reduce(into: (cases: 0, hospitalizations: 0, deaths: 0), { (result, entry) in
                result.cases += entry.totalReported ?? 0
                result.hospitalizations += entry.hospitalAdmissions ?? 0
                result.deaths += entry.deceased ?? 0
            })

        let positiveCasesNumbers = SummaryNumbers(
            new: todayCounts?.cases,
            trend: trend(today: todayCounts?.cases, yesterday: yesterdaysCounts?.cases),
            total: totalCounts?.cases
        )

        let hospitalAdmissionsNumbers = SummaryNumbers(
            new: todayCounts?.hospitalizations,
            trend: trend(today: todayCounts?.hospitalizations, yesterday: yesterdaysCounts?.hospitalizations),
            total: totalCounts?.hospitalizations
        )

        let deathNumbers = SummaryNumbers(
            new: todayCounts?.deaths,
            trend: trend(today: todayCounts?.deaths, yesterday: yesterdaysCounts?.deaths),
            total: totalCounts?.deaths
        )

        guard let updatedAt = lastModified, let numbersDate = todaysEntries?.first?.dateOfPublication else {
            fatalError("Missing dates")
        }

        let summary = Summary(updatedAt: updatedAt,
                              numbersDate: numbersDate,
                              regionCode: "NL0",
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

        var municipalSummaries = [Summary]()
        var securityRegionSummaries = [Summary]()

        for entry in todaysEntries ?? [] {

            let isMunicipality = entry.municipalityCode != nil
            let regionCode = entry.municipalityCode ?? entry.securityRegionCode ?? "XX0"

            let totals: (positiveCases: Int, hospitalAdmissions: Int, deaths: Int)?
            if isMunicipality {
                totals = allEntries?
                    .filter { $0.municipalityCode == regionCode }
                    .compactMap { $0 }
                    .reduce(into: (positiveCases: 0, hospitalAdmissions: 0, deaths: 0), { (result, entry) in
                        result.positiveCases += entry.totalReported ?? 0
                        result.hospitalAdmissions += entry.hospitalAdmissions ?? 0
                        result.deaths += entry.deceased ?? 0
                    })
            } else {
                totals = allEntries?
                    .filter { $0.securityRegionCode == regionCode }
                    .compactMap { $0 }
                    .reduce(into: (positiveCases: 0, hospitalAdmissions: 0, deaths: 0), { (result, entry) in
                        result.positiveCases += entry.totalReported ?? 0
                        result.hospitalAdmissions += entry.hospitalAdmissions ?? 0
                        result.deaths += entry.deceased ?? 0
                    })
            }

            let todays: RIVMRegionalEntry?
            if isMunicipality {
                todays = todaysEntries?.first(where: { $0.municipalityCode == regionCode })
            } else {
                todays = todaysEntries?.first(where: { $0.securityRegionCode == regionCode })
            }

            let yesterdays: RIVMRegionalEntry?
            if isMunicipality {
                yesterdays = yesterdaysEntries?.first(where: { $0.municipalityCode == regionCode })
            } else {
                yesterdays = yesterdaysEntries?.first(where: { $0.securityRegionCode == regionCode })
            }

            let positiveCases = SummaryNumbers(
                new: todays?.totalReported,
                trend: trend(today: todays?.totalReported, yesterday: yesterdays?.totalReported),
                total: totals?.positiveCases
            )

            let hospitalAdmissions = SummaryNumbers(
                new: todays?.hospitalAdmissions,
                trend: trend(today: todays?.hospitalAdmissions, yesterday: yesterdays?.hospitalAdmissions),
                total: totals?.hospitalAdmissions
            )

            let deaths = SummaryNumbers(
                new: todays?.deceased,
                trend: trend(today: todays?.deceased, yesterday: yesterdays?.deceased),
                total: totals?.deaths
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

            if isMunicipality {
                municipalSummaries.append(summary)
            } else {
                securityRegionSummaries.append(summary)
            }
        }

        let allMunicipalitiesDTO = GroupedRegionsDTO(
            updatedAt: updatedAt,
            numbersDate: numbersDate,
            regions: municipalSummaries.map { $0.nillifyingDates() }
        )

        let allMunicipalitiesJSON = try encoder.encode(allMunicipalitiesDTO)

        let allMunicipalitiesURL = latestURL.appendingPathComponent("municipalities.json")

        FileManager.default.createFile(atPath: allMunicipalitiesURL.path, contents: allMunicipalitiesJSON)

        let allSecurityRegionsDTO = GroupedRegionsDTO(
            updatedAt: updatedAt,
            numbersDate: numbersDate,
            regions: securityRegionSummaries.map { $0.nillifyingDates() }
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
