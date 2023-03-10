//
//  TransactionController.swift
//  
//
//  Created by Robert Cheal on 4/22/22.
//

import Vapor
import MyMusic

struct TransactionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let version = routes.grouped("v1")
        version.get("transactions", use: getTransactions(req:))
    }

    private func getTransactions(req: Request) async throws -> APITransactions {
        let ds = Datastore.shared()
        let query = try req.query.decode(StartTime.self)
        var transactions: [Transaction] = []
        var transactionCount = 0
        if let startTime = query.startTime {
            transactions = try await ds.getTransactions(since: startTime)
            transactionCount = transactions.count
        } else {
            transactions = try await ds.getTransactions(since: "0")
            transactionCount = transactions.count
        }
        let metadata = APIMetadata(totalCount: transactionCount, limit: transactionCount, offset: 0)
        return APITransactions(transactions: transactions, _metadata: metadata)
    }

}
