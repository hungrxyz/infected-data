//
//  File.swift
//  
//
//  Created by marko on 12/13/20.
//

import Foundation

struct NICEEntry: Entry {

    let date: Date
    let value: Int

}

extension NICEEntry: Decodable {
}
