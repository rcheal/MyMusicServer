//
//  Transactions.swift
//  
//
//  Created by Robert Cheal on 1/15/21.
//

import Foundation
import MusicMetadata
import Vapor

struct Transactions {
    var transactions: [Transaction]
}

extension Transactions: Codable, Content {
    
    public enum CodingKeys: String, CodingKey {
        case transactions
    }
}
