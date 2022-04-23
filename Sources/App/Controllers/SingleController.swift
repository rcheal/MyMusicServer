//
//  SingleController.swift
//  
//
//  Created by Robert Cheal on 4/22/22.
//

import Vapor
import MusicMetadata

struct SingleController: RouteCollection {

    // MARK: - Routes

    func boot(routes: RoutesBuilder) throws {
        let version = routes.grouped("v1")
        let singles = version.grouped("singles")
        singles.get(use: getSingles(req:))

        let single = singles.grouped(":id")
        single.on(.HEAD, [], use: headSingle(req:))
        single.get(use: getSingle(req:))
        single.on(.POST, [], body: .collect(maxSize: 200000), use: postSingle(req:))
        single.on(.PUT, [], body: .collect(maxSize: 200000), use: putSingle(req:))
        single.delete(use: deleteSingle(req:))

        let file = single.grouped(":filename")
        file.get(use: getSingleFile(req:))
        file.on(.POST, [], body: .collect(maxSize: 400000000), use: postSingleFile(req:))
        file.on(.PUT, [], body: .collect(maxSize: 400000000), use: putSingleFile(req:))
        file.delete(use: deleteSingleFile(req:))

    }

    // MARK: - Route Handlers

    // GET /singles
    private func getSingles(req: Request) async throws -> APISingles {
        let params = try req.query.decode(ListParams.self)
        let limit = params.limit ?? 10
        let offset = params.offset ?? 0
        let singles = try Datastore.sharedInstance!.getSingles(limit: limit, offset: offset, fields: params.fields)
        let singleCount = Datastore.sharedInstance!.getSingleCount()
        let metadata = APIMetadata(totalCount: singleCount, limit: limit, offset: offset)
        return APISingles(singles: singles, _metadata: metadata)
    }

    // MARK: Singles
    // HEAD /singles/:id
    private func headSingle(req: Request) throws -> HTTPResponseStatus {
        if let id = req.parameters.get("id") {
            if try Datastore.sharedInstance!.singleExists(id) {
                return(.ok)
            } else {
                return(.notFound)
            }
        }
        throw Abort(.notFound)
    }

    // GET /singles/:id
    private func getSingle(req: Request) async throws -> Single {
        if let id = req.parameters.get("id") {
            if let single = try Datastore.sharedInstance!.getSingle(id) {
                return single
            }
        }
        throw Abort(.notFound)
    }

    // POST /singles/:id
    private func postSingle(req: Request) async throws -> Transaction {
        let id = req.parameters.get("id")!
        let single = try req.content.decode(Single.self)

        if id != single.id {
            throw Abort(.conflict)
        }

        do {
            return try Datastore.sharedInstance!.postSingle(single)

        } catch {
            throw Abort(.conflict)
        }
    }

    // PUT /singles/:id

    private func putSingle(req: Request) async throws -> Transaction {
        let id = req.parameters.get("id")!
        let single = try req.content.decode(Single.self)

        if id != single.id {
            throw Abort(.conflict)
        }

        return try Datastore.sharedInstance!.putSingle(single)
    }

    // DELETE /singles/:id
    private func deleteSingle(req: Request) async throws -> Transaction {
        let id = req.parameters.get("id")!

        return try Datastore.sharedInstance!.deleteSingle(id)
    }

    // MARK: Single files

    // GET /singles/:id/:filename
    private func getSingleFile(req: Request) async throws -> Response {
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            if let path = Datastore.sharedInstance!.getSingleFilePath(id, filename: filename) {
                return req.fileio.streamFile(at: path)
            }
        }
        throw Abort(.badRequest)
    }

    // POST /singles/:id/:filename
    private func postSingleFile(req: Request) async throws -> HTTPResponseStatus {
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            if let value = req.body.data {
                let data = Data(buffer: value)
                try Datastore.sharedInstance!.postSingleFile(id, filename: filename, data: data)
                return HTTPResponseStatus.ok
            }
            return HTTPResponseStatus.noContent
        }

        return HTTPResponseStatus.badRequest
    }

    // PUT /singles/:id/:filename
    private func putSingleFile(req: Request) async throws -> HTTPResponseStatus {
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            if let value = req.body.data {
                let data = Data(buffer: value)
                try Datastore.sharedInstance!.putSingleFile(id, filename: filename, data: data)
                return HTTPResponseStatus.ok
            }
            return HTTPResponseStatus.noContent
        }
        return HTTPResponseStatus.badRequest
    }

    // DELETE /singles/:id/:filename
    private func deleteSingleFile(req: Request) async throws -> HTTPResponseStatus {
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            try Datastore.sharedInstance!.deleteSingleFile(id, filename: filename)
            return HTTPResponseStatus.ok
        }
        return HTTPResponseStatus.badRequest
    }

}
