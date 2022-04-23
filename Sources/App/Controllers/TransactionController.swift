//
//  TransactionController.swift
//  
//
//  Created by Robert Cheal on 4/22/22.
//

import Vapor
import MusicMetadata

struct TransactionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let version = routes.grouped("v1")
        version.get("transactions", use: getTransactions(req:))
    }

    private func getTransactions(req: Request) async throws -> APITransactions {
        let ds = Datastore.shared()
        let query = try req.query.decode(StartTime.self)
        if let startTime = query.startTime {
            return APITransactions(transactions: try await ds.getTransactions(since: startTime))
        } else {
            return APITransactions(transactions: try await ds.getTransactions(since: "20000101"))
        }
    }

}
