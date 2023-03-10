//
//  AlbumController.swift
//  
//
//  Created by Robert Cheal on 4/21/22.
//

import Vapor
import MyMusic

struct AlbumController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let version = routes.grouped("v1")
        let albums = version.grouped("albums")
        albums.get(use: getAlbums(req:))

        let album = albums.grouped(":id")
        album.on(.HEAD, [], use: headAlbum(req:))
        album.get(use: getAlbum(req:))
        album.on(.POST, [], body: .collect(maxSize: 200_000), use: postAlbum(req:))
        album.on(.PUT, [], body: .collect(maxSize: 200_000), use: putAlbum(req:))
        album.delete(use: deleteAlbum(req:))

        let file = album.grouped(":filename")
        file.get(use: getAlbumFile(req:))
        file.on(.POST, [], body: .collect(maxSize: 400_000_000), use: postAlbumFile(req:))
        file.on(.PUT, [], body: .collect(maxSize: 400_000_000), use: putAlbumFile(req:))
        file.delete(use: deleteAlbumFile(req:))

    }

    // GET /albums
    private func getAlbums(req: Request) async throws -> APIAlbums {
        let ds = Datastore.shared()
        let params = try req.query.decode(ListParams.self)
        let limit = params.limit ?? 10
        let offset = params.offset ?? 0
        let albums = try await ds.getAlbums(limit: limit, offset: offset, fields: params.fields)
        let albumCount = try await ds.getAlbumCount()
        let metadata = APIMetadata(totalCount: albumCount, limit: limit, offset: offset)
        return APIAlbums(albums: albums, _metadata: metadata)
    }

    // MARK: - Album file methods

    // GET /albums/:id/:filename
    private func getAlbumFile(req: Request) async throws -> Response {
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            if let path = try await Datastore.shared().getAlbumFilePath(id, filename: filename) {
                return req.fileio.streamFile(at: path)
            }
        }
        throw Abort(.badRequest)
    }

    // POST /albums/:id/:filename
    private func postAlbumFile(req: Request) async throws -> HTTPResponseStatus {
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            if let value = req.body.data {
                let data = Data(buffer: value)
                try await Datastore.shared().postAlbumFile(id, filename: filename, data: data)
                return HTTPResponseStatus.ok
            }
            return HTTPResponseStatus.noContent
        }

        return HTTPResponseStatus.badRequest
    }

    // PUT /albums/:id/:filename
    private func putAlbumFile(req: Request) async throws -> HTTPResponseStatus {
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            if let value = req.body.data {
                let data = Data(buffer: value)
                try await Datastore.shared().putAlbumFile(id, filename: filename, data: data)
                return HTTPResponseStatus.ok
            }
            return HTTPResponseStatus.noContent
        }
        return HTTPResponseStatus.badRequest
    }

    // DELETE /albums/:id/:filename
    private func deleteAlbumFile(req: Request) async throws -> HTTPResponseStatus {
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            try await Datastore.shared().deleteAlbumFile(id, filename: filename)
            return HTTPResponseStatus.ok
        }
        return HTTPResponseStatus.badRequest
    }

    // MARK: - Album methods
    // HEAD /albums/:id
    private func headAlbum(req: Request) async throws -> HTTPResponseStatus {
        if let id = req.parameters.get("id") {
            if try await Datastore.shared().albumExists(id) {
                return(.ok)
            } else {
                return(.notFound)
            }
        }
        throw Abort(.notFound)
    }

    // GET /albums/:id
    private func getAlbum(req: Request) async throws -> Album {
        if let id = req.parameters.get("id") {
            if let album = try await Datastore.shared().getAlbum(id) {
                return album
            }
        }
        throw Abort(.notFound)
    }

    // POST /albums/:id
    private func postAlbum(req: Request) async throws -> Transaction {
        let id = req.parameters.get("id")!
        let content = req.content

        let album = try content.decode(Album.self)

        if id != album.id {
            throw Abort(.conflict)
        }

        do {
            return try await Datastore.shared().postAlbum(album)

        } catch {
            throw Abort(.conflict)
        }
    }

    // PUT /albums/:id

    private func putAlbum(req: Request) async throws -> Transaction {
        let id = req.parameters.get("id")!
        let album = try req.content.decode(Album.self)

        if id != album.id {
            throw Abort(.conflict)
        }

        return try await Datastore.shared().putAlbum(album)
    }

    // DELETE /albums/:id
    private func deleteAlbum(req: Request) async throws -> Transaction {
        let id = req.parameters.get("id")!

        return try await Datastore.shared().deleteAlbum(id)
    }

}


