//
//  TransactionList.swift
//  
//
//  Created by Robert Cheal on 1/15/21.
//

import Foundation
import Vapor

struct TransactionList {
    var transactions: [Transaction]
}

extension TransactionList: Codable, Content {
    
    public enum CodingKeys: String, CodingKey {
        case transactions
    }
}
