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
        file.on(.POST, [], body: .stream, use: postAlbumFile(req:))
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


    private func createFile(_ filePath: String, dirPath: String) -> Bool {
        let fm = FileManager.default
        do {
            if !fm.fileExists(atPath: filePath) {
                try fm.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            return false
        }
        return fm.createFile(atPath: filePath, contents: nil)
    }

    private func postAlbumFile(req: Request, filePath: String, dirPath: String) throws -> EventLoopFuture<HTTPResponseStatus> {
        let statusPromise = req.eventLoop.makePromise(of: HTTPResponseStatus.self)
        guard createFile(filePath, dirPath: dirPath) else {
            throw Abort(HTTPResponseStatus.internalServerError)
        }

        // Configure SwiftNIO to create a file stream.
        let nbFileIO = NonBlockingFileIO(threadPool: req.application.threadPool) // Should move out of the func, but left it here for ease of understanding.
        let fileHandle = nbFileIO.openFile(path: filePath, mode: .write, eventLoop: req.eventLoop)

        // Launch the stream...
        return fileHandle.map { handle in
            // Vapor request will now feed us bytes
            req.body.drain { someResult -> EventLoopFuture<Void> in
                let drainPromise = req.eventLoop.makePromise(of: Void.self)

                switch someResult {
                case .buffer(let byteBuffer):
                    // We have bytes. So, write them to disk, and handle our promise
                    _ = nbFileIO.write(fileHandle: handle, buffer: byteBuffer, eventLoop: req.eventLoop)
                        .always { outcome in
                            switch outcome {
                            case .success(let success):
                                drainPromise.succeed(success)
                            case .failure(let failure):
                                drainPromise.fail(failure)
                            }
                        }
                case .error(let error):
                    do {
                        // Handle errors by closing and removing our file
                        req.logger.error("Upload error on \(filePath): \(error.localizedDescription)")
                        try? handle.close()
                        try FileManager.default.removeItem(atPath: filePath)
                    } catch {
                        req.logger.error("Catastrophic failure on \(error.localizedDescription)")
                    }
                        // Inform the Client
                    statusPromise.succeed(.internalServerError)
                case .end:
                    try? handle.close()
                    drainPromise.succeed(())
                    statusPromise.succeed(.ok)
                }
                return drainPromise.futureResult
            }
        }.transform(to: statusPromise.futureResult)
    }

    private func postAlbumFile(req: Request) async throws -> HTTPResponseStatus {
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {

            let (dirPath, filePath) = try await Datastore.shared().getAlbumFilePaths(id, filename: filename)
            if let dirPath, let filePath {

                let futureStatus = try postAlbumFile(req: req, filePath: filePath, dirPath: dirPath)
                return try await futureStatus.get()
            } else {
                return .internalServerError
            }
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


