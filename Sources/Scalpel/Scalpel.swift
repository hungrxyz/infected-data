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

    static let calendar = Calendar(identifier: .iso8601)
    
    func run() throws {
        let updatedAt = Date()
        let calendar = Self.calendar

        let cbsAreaProvider = CBSAreaProvider()
        let cbsAreas = try cbsAreaProvider.areas()
        let nationalPopulation = cbsAreas.reduce(into: 0) { $0 += $1.population }
        
        var rivmRegional: RIVMRegional!
        var rivmHospitalAdmissions: [RIVMHospitalAdmissionsEntry]!
        var rivmIntensiveCareAdmissions: [RIVMIntensiveCareAdmissionsEntry]?
        var lcpsEntries: [LCPSEntry]?
        var reproductionNumberEntries: [RIVMReproductionNumbersEntry]?
        var homeAdmissionEntries: [HomeAdmissionsEntry]!
        
        let group = DispatchGroup()
        
        let rivmAPI = RIVMAPI()
        
        group.enter()
        rivmAPI.regional { result in
            rivmRegional = try! result.get()
            group.leave()
        }
        
        group.enter()
        rivmAPI.hospitalAdmissions { result in
            rivmHospitalAdmissions = try! result.get()
            group.leave()
        }
        
        group.enter()
        rivmAPI.intensiveCareAdmissions { result in
            rivmIntensiveCareAdmissions = try! result.get()
            group.leave()
        }
        
        group.enter()
        LCPSAPI().entries { result in
            lcpsEntries = try! result.get()
            group.leave()
        }

        group.enter()
        rivmAPI.reproductionNumber { result in
            reproductionNumberEntries = try! result.get()
            group.leave()
        }

        group.enter()
        HomeAdmissionsAPI().admissions { result in
            homeAdmissionEntries = try! result.get()
            group.leave()
        }
        
        group.wait()
        
        let accumulator = NumbersAccumulator()
        
        let allEntries = rivmRegional.entries
        
        // MARK: - National
        
        // MARK: RIVM
        
        let totalCounts = accumulator.accumulate(entries: allEntries)
        
        let todaysEntries = allEntries.filter { calendar.isDateInToday($0.dateOfPublication) }
        let todayCounts = accumulator.accumulate(entries: todaysEntries)
        
        let yesterdaysEntries = allEntries.filter { calendar.isDateInYesterday($0.dateOfPublication) }
        let yesterdaysCounts = accumulator.accumulate(entries: yesterdaysEntries)
        
        let latestRIVMHospitalAdmissionEntries = rivmHospitalAdmissions.filter { calendar.isDate($0.date, inSameDayAsDaysAgo: 1) }
        let previousRIVMHospitalAdmissionEntries = rivmHospitalAdmissions.filter { calendar.isDate($0.date, inSameDayAsDaysAgo: 2) }

        let latestNationalRIVMHospitalAdmissions = latestRIVMHospitalAdmissionEntries.accumulatedHospitalAdmissions()
        let previousNationalRIVMHospitalAdmissions = previousRIVMHospitalAdmissionEntries.accumulatedHospitalAdmissions()

        let latestIntensiveCareAdmissions = rivmIntensiveCareAdmissions?.last?.icAdmissionNotification
        let previousIntensiveCareAdmissions = rivmIntensiveCareAdmissions?.dropLast().last?.icAdmissionNotification

        guard let numbersDate = todaysEntries.first?.dateOfPublication else {
            fatalError("Missing todays entries dates")
        }

        // MARK: LCPS
        
        let latestLCPSEntry = lcpsEntries?.first { calendar.isDateInToday($0.date) }
        let previousLCPSEntry = lcpsEntries?.first { calendar.isDateInYesterday($0.date) }
        
        // MARK: Hospital Occupancy
        
        let hospitalOccupancy: Occupancy?
        if let latestLCPSEntry = latestLCPSEntry,
           let previousLCPSEntry = previousLCPSEntry {
            
            hospitalOccupancy = Occupancy(
                newAdmissions: latestNationalRIVMHospitalAdmissions,
                newAdmissionsTrend: trend(today: latestNationalRIVMHospitalAdmissions, yesterday: previousNationalRIVMHospitalAdmissions),
                newAdmissionsPer100KInhabitants: per100k(number: latestNationalRIVMHospitalAdmissions, population: nationalPopulation),
                currentlyOccupied: latestLCPSEntry.clinicCOVIDOccupancy,
                currentlyOccupiedTrend: trend(today: latestLCPSEntry.clinicCOVIDOccupancy, yesterday: previousLCPSEntry.clinicCOVIDOccupancy)
            )
        } else {
            hospitalOccupancy = nil
        }
        
        // MARK: Intensive Care Occupancy
        
        let intensiveCareOccupancy: Occupancy?
        if let latestIntensiveCareAdmissions = latestIntensiveCareAdmissions,
           let previousIntensiveCareAdmissions = previousIntensiveCareAdmissions,
           let latestLCPSEntry = latestLCPSEntry,
           let previousLCPSEntry = previousLCPSEntry {
            
            intensiveCareOccupancy = Occupancy(
                newAdmissions: latestIntensiveCareAdmissions,
                newAdmissionsTrend: trend(today: latestIntensiveCareAdmissions, yesterday: previousIntensiveCareAdmissions),
                newAdmissionsPer100KInhabitants: per100k(number: latestIntensiveCareAdmissions, population: nationalPopulation),
                currentlyOccupied: latestLCPSEntry.intensiveCareCOVIDOccupancy,
                currentlyOccupiedTrend: trend(today: latestLCPSEntry.intensiveCareCOVIDOccupancy, yesterday: previousLCPSEntry.intensiveCareCOVIDOccupancy)
            )
        } else {
            intensiveCareOccupancy = nil
        }

        let reproductionNumber = reproductionNumberEntries?.last(where: { $0.average != nil })?.average
        
        let summarizedNumbers = summarizeEntries(today: todayCounts,
                                                 yesterday: yesterdaysCounts,
                                                 total: totalCounts,
                                                 population: nationalPopulation,
                                                 reproductionNumber: reproductionNumber)
        
        let nationalHospitalizationsPer100K = hospitalOccupancy?.newAdmissions.flatMap { per100k(number: $0, population: nationalPopulation) }
        
        let nationalHospitalizationsSummary = SummaryNumbers(
            new: hospitalOccupancy?.newAdmissions,
            trend: hospitalOccupancy?.newAdmissionsTrend,
            total: accumulator.accumulateHospitalAdmissions(fromEntries: rivmHospitalAdmissions),
            average: nil,
            per100KInhabitants: nationalHospitalizationsPer100K,
            percentageOfPopulation: nil,
            herdImmunityCurrentTrendDate: nil,
            herdImmunityEstimatedDate: nil
        )

        // MARK: Home Admissions

        let latestNewHomeAdmissions = NewHomeAdmissionsCalculator(entries: homeAdmissionEntries)()
        let previousNewHomeAdmissions = NewHomeAdmissionsCalculator(entries: Array(homeAdmissionEntries.dropFirst()))()

        let newHomeAdmissionsTrend = trend(today: latestNewHomeAdmissions, yesterday: previousNewHomeAdmissions)

        let per100KNewHomeAdmissions = per100k(number: latestNewHomeAdmissions, population: nationalPopulation)

        let latestActiveHomeAdmissions = ActiveHomeAdmissionsCalculator(entry: homeAdmissionEntries[0])()
        let previousActiveHomeAdmissions = ActiveHomeAdmissionsCalculator(entry: homeAdmissionEntries[1])()

        let activeHomeAdmissionsTrend = trend(today: latestActiveHomeAdmissions, yesterday: previousActiveHomeAdmissions)

        let homeAdmissionsSummary = Occupancy(
            newAdmissions: latestNewHomeAdmissions,
            newAdmissionsTrend: newHomeAdmissionsTrend,
            newAdmissionsPer100KInhabitants: per100KNewHomeAdmissions,
            currentlyOccupied: latestActiveHomeAdmissions,
            currentlyOccupiedTrend: activeHomeAdmissionsTrend
        )

        // MARK: Vaccinations
        
        let vaccinationEntries = try Vaccinations().administered()
        let vaccinationDeliveries = try Vaccinations().deliveries()
        
        let currentVaccinationsTotal = vaccinationEntries.last!.doses
        
        let newVaccinations = NewVaccinationsCalculator(entries: vaccinationEntries)()
        let vaccinationsCoverage = VaccionationCoverageCalculator(entry: vaccinationEntries.last!,
                                                                  population: nationalPopulation)()
        
        let herdImmunityCurrentTrendCalculator = HerdImmunityCurrentTrendCalculator(calendar: calendar,
                                                                        vaccinationEntries: vaccinationEntries,
                                                                        population: nationalPopulation)

        let herdImmunityEstimationCalculator = HerdImmunityEstimationCalculator(calendar: calendar,
                                                                                vaccinationEntries: vaccinationEntries,
                                                                                vaccinationDeliveries: vaccinationDeliveries,
                                                                                population: nationalPopulation)

        let averageCalculator = NewVaccinationsAverageCalculator(entries: Array(vaccinationEntries.suffix(8)))
        let averageTrendCalculator = NewVaccinationsAverageTrendCalculator(entries: vaccinationEntries)
        
        let vaccinationsSummaryNumbers = SummaryNumbers(new: newVaccinations,
                                                        trend: averageTrendCalculator(),
                                                        total: currentVaccinationsTotal,
                                                        average: averageCalculator(),
                                                        per100KInhabitants: nil,
                                                        percentageOfPopulation: vaccinationsCoverage,
                                                        herdImmunityCurrentTrendDate: herdImmunityCurrentTrendCalculator(),
                                                        herdImmunityEstimatedDate: herdImmunityEstimationCalculator())
        
        let summary = Summary(updatedAt: updatedAt,
                              numbersDate: numbersDate,
                              regionCode: "NL00",
                              municupalityName: nil,
                              provinceName: nil,
                              securityRegionName: nil,
                              positiveCases: summarizedNumbers.positiveCases,
                              hospitalAdmissions: nationalHospitalizationsSummary,
                              hospitalOccupancy: hospitalOccupancy,
                              intensiveCareOccupancy: intensiveCareOccupancy,
                              homeAdmissions: homeAdmissionsSummary,
                              deaths: summarizedNumbers.deaths,
                              vaccinations: vaccinationsSummaryNumbers)
        
        let encoder = JSONEncoder()
        
        if #available(OSX 10.15, *) {
            let iso8601WithTimeZoneFormatter = ISO8601DateFormatter()
            iso8601WithTimeZoneFormatter.timeZone = .amsterdam
            
            encoder.dateEncodingStrategy = .custom({ (date, encoder) in
                let stringRepresentation = iso8601WithTimeZoneFormatter.string(from: date)
                var container = encoder.singleValueContainer()
                try container.encode(stringRepresentation)
            })
            
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
        
        let nlRegionURL = regionURL.appendingPathComponent("NL00.json")
        
        FileManager.default.createFile(atPath: nlRegionURL.path, contents: summaryJSON)
        
        // MARK: - Municipalities
        
        let populationPerMunicipality = cbsAreas.reduce(into: [String: Int]()) { $0[$1.municipalityCode] = $1.population }
        
        var municipalSummaries = [Summary]()
        
        let municipalEntries = todaysEntries.filter { $0.municipalityCode != nil }
        
        for entry in municipalEntries {
            
            let regionCode = entry.municipalityCode!
            
            // Some municipalities are duplicated. For example: Amsterdam.
            if municipalSummaries.contains(where: { $0.regionCode == regionCode }) {
                continue
            }
            
            let totalsEntries = allEntries.filter { $0.municipalityCode == regionCode }
            let totals = accumulator.accumulate(entries: totalsEntries)
            
            guard
                let todaysEntry = todaysEntries.first(where: { $0.municipalityCode == regionCode }),
                let yesterdaysEntry = yesterdaysEntries.first(where: { $0.municipalityCode == regionCode })
            else {
                continue
            }
            
            let latestHospitalAdmissionsAverage = latestRIVMHospitalAdmissionEntries
                .filter { $0.municipalityCode == regionCode }
                .accumulatedHospitalAdmissions()
            
            let previousHospitalAdmissionsAverage = previousRIVMHospitalAdmissionEntries
                .filter { $0.municipalityCode == regionCode }
                .accumulatedHospitalAdmissions()
            
            let allHospitalAdmissionsForThisRegion = rivmHospitalAdmissions.filter { $0.municipalityCode == regionCode }
            let totalHospitalAdmissions = accumulator.accumulateHospitalAdmissions(fromEntries: allHospitalAdmissionsForThisRegion)
            
            let summarizedNumbers = summarizeEntries(
                today: (todaysEntry.totalReported ?? 0, latestHospitalAdmissionsAverage, todaysEntry.deceased ?? 0),
                yesterday: (yesterdaysEntry.totalReported ?? 0, previousHospitalAdmissionsAverage, yesterdaysEntry.deceased ?? 0),
                total: (totals.positiveCases, totalHospitalAdmissions, totals.deaths),
                population: populationPerMunicipality[regionCode]
            )
            
            let summary = Summary(
                updatedAt: updatedAt,
                numbersDate: numbersDate,
                regionCode: regionCode,
                municupalityName: entry.municipalityName,
                provinceName: entry.provinceName,
                securityRegionName: entry.securityRegionName,
                positiveCases: summarizedNumbers.positiveCases,
                hospitalAdmissions: summarizedNumbers.hospitalAdmissions,
                hospitalOccupancy: nil,
                intensiveCareOccupancy: nil,
                homeAdmissions: nil,
                deaths: summarizedNumbers.deaths,
                vaccinations: nil
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
        
        let populationPerSafetyRegion = cbsAreas.reduce(into: [String: Int]()) {
            $0[$1.securityRegionCode] = ($0[$1.securityRegionCode] ?? 0) + $1.population
        }
        
        var securityRegionsSummaries = [Summary]()
        
        let safetyRegionCodeNameMap = cbsAreas.reduce(into: [String: String]()) { $0[$1.securityRegionCode] = $1.securityRegionName }
        let securityRegionCodes = Array(safetyRegionCodeNameMap.keys).sorted()
        
        for regionCode in securityRegionCodes {
            
            let totalsEntries = allEntries.filter { $0.securityRegionCode == regionCode }
            let totals = accumulator.accumulate(entries: totalsEntries)
            
            let todaysEntriesForSecurityRegion = todaysEntries.filter { $0.securityRegionCode == regionCode }
            let todaysNumbers = accumulator.accumulate(entries: todaysEntriesForSecurityRegion)
            
            let yesterdaysEntriesForSecurityRegion = yesterdaysEntries.filter { $0.securityRegionCode == regionCode }
            let yesterdaysNumbers = accumulator.accumulate(entries: yesterdaysEntriesForSecurityRegion)
            
            let latestHospitalAdmissionsAverage = latestRIVMHospitalAdmissionEntries
                .filter { $0.securityRegionCode == regionCode }
                .accumulatedHospitalAdmissions()
            
            let previousHospitalAdmissionsAverage = previousRIVMHospitalAdmissionEntries
                .filter { $0.securityRegionCode == regionCode }
                .accumulatedHospitalAdmissions()
            
            let allHospitalAdmissionsForThisRegion = rivmHospitalAdmissions.filter { $0.securityRegionCode == regionCode }
            let totalHospitalAdmissions = accumulator.accumulateHospitalAdmissions(fromEntries: allHospitalAdmissionsForThisRegion)
            
            let summarizedNumbers = summarizeEntries(
                today: (todaysNumbers.positiveCases, latestHospitalAdmissionsAverage, todaysNumbers.deaths),
                yesterday: (yesterdaysNumbers.positiveCases, previousHospitalAdmissionsAverage, yesterdaysNumbers.deaths),
                total: (totals.positiveCases, totalHospitalAdmissions, totals.deaths),
                population: populationPerSafetyRegion[regionCode]
            )
            
            let provinceName = todaysEntriesForSecurityRegion.first?.provinceName
                ?? cbsAreas.first(where: { $0.securityRegionCode == regionCode })?.provinceName
            let securityRegionName = todaysEntriesForSecurityRegion.first?.securityRegionName
                ?? cbsAreas.first(where: { $0.securityRegionCode == regionCode })?.securityRegionName
            
            let summary = Summary(
                updatedAt: updatedAt,
                numbersDate: numbersDate,
                regionCode: regionCode,
                municupalityName: nil,
                provinceName: provinceName,
                securityRegionName: securityRegionName,
                positiveCases: summarizedNumbers.positiveCases,
                hospitalAdmissions: summarizedNumbers.hospitalAdmissions,
                hospitalOccupancy: nil,
                intensiveCareOccupancy: nil,
                homeAdmissions: nil,
                deaths: summarizedNumbers.deaths,
                vaccinations: nil
            )
            
            let json = try encoder.encode(summary)
            
            let filename = [regionCode, "json"].joined(separator: ".")
            let fileURL = regionURL.appendingPathComponent(filename)
            
            FileManager.default.createFile(atPath: fileURL.path, contents: json, attributes: nil)
            
            securityRegionsSummaries.append(summary)
        }
        
        let groupedSecurityRegions = securityRegionsSummaries
            .sorted(by: { ($0.securityRegionName ?? "zzz") < ($1.securityRegionName ?? "zzz") })
            .map { $0.nillifyingDates() }
        
        let allSecurityRegionsDTO = GroupedRegionsDTO(
            updatedAt: updatedAt,
            numbersDate: numbersDate,
            regions: groupedSecurityRegions
        )
        
        let allSecurityRegionsJSON = try encoder.encode(allSecurityRegionsDTO)
        
        let allSecurityRegionsURL = latestURL.appendingPathComponent("security_regions.json")
        
        FileManager.default.createFile(atPath: allSecurityRegionsURL.path, contents: allSecurityRegionsJSON)
        
        // MARK: - Provinces
        
        let populationPerProvince = cbsAreas.reduce(into: [String: Int]()) {
            $0[$1.provinceCode] = ($0[$1.provinceCode] ?? 0) + $1.population
        }
        
        // Dictionary with province name as key and province code as value.
        let provinceNameCodeMap = cbsAreas.reduce(into: [String: String]()) { $0[$1.provinceName] = $1.provinceCode }
        let provinceNames = Array(provinceNameCodeMap.keys).sorted()
        
        let provinceNameSafetyRegionCodesMap = cbsAreas
            .reduce(into: [String: Set<String>]()) { $0[$1.provinceName] = Set(($0[$1.provinceName] ?? []) + [$1.securityRegionCode]) }
        
        var provincesSummaries = [Summary]()
        
        for provinceName in provinceNames {
            
            let regionCode = provinceNameCodeMap[provinceName]!
            
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
            
            let safetyRegionCodes = provinceNameSafetyRegionCodesMap[provinceName] ?? []
            
            let latestHospitalAdmissionsAverage = latestRIVMHospitalAdmissionEntries
                .filter { $0.securityRegionCode.flatMap(safetyRegionCodes.contains) ?? false }
                .accumulatedHospitalAdmissions()
            
            let previousHospitalAdmissionsAverage = previousRIVMHospitalAdmissionEntries
                .filter { $0.securityRegionCode.flatMap(safetyRegionCodes.contains) ?? false }
                .accumulatedHospitalAdmissions()
            
            let allHospitalAdmissionsForThisRegion = rivmHospitalAdmissions
                .filter { $0.securityRegionCode.flatMap(safetyRegionCodes.contains) ?? false }
            let totalHospitalAdmissions = accumulator.accumulateHospitalAdmissions(fromEntries: allHospitalAdmissionsForThisRegion)
            
            let summarizedNumbers = summarizeEntries(
                today: (todaysNumbers.positiveCases, latestHospitalAdmissionsAverage, todaysNumbers.deaths),
                yesterday: (yesterdaysNumbers.positiveCases, previousHospitalAdmissionsAverage, yesterdaysNumbers.deaths),
                total: (totals.positiveCases, totalHospitalAdmissions, totals.deaths),
                population: populationPerProvince[regionCode]
            )
            
            let summary = Summary(
                updatedAt: updatedAt,
                numbersDate: numbersDate,
                regionCode: regionCode,
                municupalityName: nil,
                provinceName: provinceName,
                securityRegionName: nil,
                positiveCases: summarizedNumbers.positiveCases,
                hospitalAdmissions: summarizedNumbers.hospitalAdmissions,
                hospitalOccupancy: nil,
                intensiveCareOccupancy: nil,
                homeAdmissions: nil,
                deaths: summarizedNumbers.deaths,
                vaccinations: nil
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
    
    func per100k(number: Int, population: Int) -> Float {
        (Float(number) / Float(population)) * 100_000
    }
    
    func summarizeEntries(today: AccumulatedNumbers,
                          yesterday: AccumulatedNumbers,
                          total: AccumulatedNumbers,
                          population: Int?,
                          reproductionNumber: Float? = nil) -> (positiveCases: SummaryNumbers, hospitalAdmissions: SummaryNumbers, deaths: SummaryNumbers) {
        
        let positiveCases = SummaryNumbers(
            new: today.positiveCases,
            trend: trend(today: today.positiveCases, yesterday: yesterday.positiveCases),
            total: total.positiveCases,
            average: nil,
            per100KInhabitants: population.flatMap { per100k(number: today.positiveCases, population: $0) },
            percentageOfPopulation: reproductionNumber,
            herdImmunityCurrentTrendDate: nil,
            herdImmunityEstimatedDate: nil
        )
        
        let hospitalAdmissions = SummaryNumbers(
            new: today.hospitalAdmissions,
            trend: trend(today: today.hospitalAdmissions, yesterday: yesterday.hospitalAdmissions),
            total: total.hospitalAdmissions,
            average: nil,
            per100KInhabitants: population.flatMap { per100k(number: today.hospitalAdmissions, population: $0) },
            percentageOfPopulation: nil,
            herdImmunityCurrentTrendDate: nil,
            herdImmunityEstimatedDate: nil
        )
        
        let deaths = SummaryNumbers(
            new: today.deaths,
            trend: trend(today: today.deaths, yesterday: yesterday.deaths),
            total: total.deaths,
            average: nil,
            per100KInhabitants: population.flatMap { per100k(number: today.deaths, population: $0) },
            percentageOfPopulation: nil,
            herdImmunityCurrentTrendDate: nil,
            herdImmunityEstimatedDate: nil
        )
        
        return (positiveCases, hospitalAdmissions, deaths)
        
    }
    
}

private extension Array where Element == RIVMHospitalAdmissionsEntry {
    
    func accumulatedHospitalAdmissions() -> Int {
        reduce(into: 0) { $0 += $1.hospitalAdmissionNotification ?? 0 }
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
                hospitalOccupancy: hospitalOccupancy,
                intensiveCareOccupancy: intensiveCareOccupancy,
                homeAdmissions: homeAdmissions,
                deaths: deaths,
                vaccinations: vaccinations)
    }
    
}

private extension RIVMRegionalEntry {
    
    var accumulatedNumbers: AccumulatedNumbers {
        (totalReported ?? 0, hospitalAdmissions ?? 0, deceased ?? 0)
    }
    
}
