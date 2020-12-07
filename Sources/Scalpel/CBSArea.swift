//
//  CBSArea.swift
//  
//
//  Created by marko on 12/7/20.
//

import Foundation

struct CBSArea {

    let municipalityName: String
    let municipalityCode: String
    let provinceName: String
    let provinceCode: String
    let securityRegionName: String
    let securityRegionCode: String
    let population: Int

}

extension CBSArea: Decodable {
}
