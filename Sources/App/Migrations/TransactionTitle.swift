//
//  TransactionTitle.swift
//  
//
//  Created by Robert Cheal on 5/28/24.
//

import Fluent

struct TransactionTitle: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("transactions")
            .field("title", .string, .required, .sql(.default("")))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("transactions")
            .deleteField("title")
            .update()
    }
}

