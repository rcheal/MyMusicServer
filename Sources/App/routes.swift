//
//  routes.swift
//
//
//  Created by Robert Cheal on 1/15/21.
//

import Vapor
import MyMusic

func routes(_ app: Application) throws {
    let _ = ServerState.shared
    let _ = Datastore.shared()

    try app.register(collection: TransactionController())

    try app.register(collection: ServerController())

    try app.register(collection: AlbumController())

    try app.register(collection: SingleController())

    try app.register(collection: PlaylistController())


}

