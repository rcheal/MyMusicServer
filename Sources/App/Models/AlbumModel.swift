//
//  AlbumModel.swift
//  
//
//  Created by Robert Cheal on 4/19/22.
//

import Vapor
import Fluent

final class AlbumModel: Model {

    static let schema = "albums"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "json")
    var json: Data

    init() { }

    init(id: UUID? = nil, json: Data) {
        self.id = id
        self.json = json
    }
}
