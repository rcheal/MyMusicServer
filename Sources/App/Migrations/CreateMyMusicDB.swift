//
//  CreateMyMusicDB.swift
//  
//
//  Created by Robert Cheal on 4/11/22.
//

import Fluent

struct CreateMyMusicDB: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("albums")
            .field("id", .uuid, .identifier(auto: false))
            .field("json", .data, .required)
            .create()

        try await database.schema("singles")
            .field("id", .uuid, .identifier(auto: false))
            .field("json", .data, .required)
            .create()

        try await database.schema("playlists")
            .field("id", .uuid, .identifier(auto: false))
            .field("user", .string)
            .field("shared", .bool, .required)
            .field("json", .data, .required)
            .create()

        try await database.schema("transactions")
            .id()
            .field("time", .string, .required)
            .field("method", .string, .required)
            .field("entity", .string, .required)
            .field("entityid", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("albums").delete()
        try await database.schema("singles").delete()
        try await database.schema("playlists").delete()
        try await database.schema("transactions").delete()
    }
}
