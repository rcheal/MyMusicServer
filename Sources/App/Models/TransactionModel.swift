//
//  TransactionModel.swift
//  
//
//  Created by Robert Cheal on 4/19/22.
//

import Vapor
import Fluent
import MusicMetadata

final class TransactionModel: Model {

    static let schema = "transactions"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "time")
    var time: String

    @Field(key: "method")
    var method: String

    @Field(key: "entity")
    var entity: String

    @Field(key: "entityid")
    var entityid: String

    init() { }

    init(id: UUID? = nil, time: String, method: String, entity: String, entityid: String) {
        self.id = id
        self.time = time
        self.method = method
        self.entity = entity
        self.entityid = entityid
    }

    init(id: UUID? = nil, transaction: Transaction) {
        self.id = id ?? UUID()
        self.time = transaction.time
        self.method = transaction.method
        self.entity = transaction.entity
        self.entityid = transaction.id
    }
}
