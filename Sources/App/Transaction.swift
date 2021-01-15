//
//  Transaction.swift
//  
//
//  Created by Robert Cheal on 1/13/21.
//

import Foundation
import Vapor

public struct Transaction: Identifiable, Hashable {
    public var id: String
    public var time: String
    public var method: String
    public var entity: String
    
    init(method: String, entity: String, id: String) {
        self.method = method
        self.entity = entity
        self.id = id

        let timestamp = ISO8601DateFormatter.string(
            from: Date(),
            timeZone: TimeZone(abbreviation: "GMT")!,
            formatOptions: [.withFullDate,.withFullTime,.withFractionalSeconds])

        self.time = timestamp
    }
}

extension Transaction: Codable, Content {
    
    public enum CodingKeys: String, CodingKey {
        case id
        case time
        case method
        case entity
    }
}

