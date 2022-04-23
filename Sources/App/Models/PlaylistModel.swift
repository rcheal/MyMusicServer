//
//  PlaylistModel.swift
//  
//
//  Created by Robert Cheal on 4/19/22.
//

import Vapor
import Fluent

final class PlaylistModel: Model {
    static let schema = "playlists"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "user")
    var user: String?

    @Field(key: "shared")
    var shared: Bool

    @Field(key: "json")
    var json: Data

    init() { }

    init(id: UUID? = nil, json: Data, user: String? = nil, shared: Bool = true) {
        self.id = id
        self.user = user
        self.shared = shared
        self.json = json
    }

}
