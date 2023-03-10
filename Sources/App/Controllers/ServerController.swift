//
//  ServerControler.swift
//  
//
//  Created by Robert Cheal on 4/22/22.
//

import Vapor
import MyMusic

struct ServerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: getServerStatus(req:))

        let version = routes.grouped("v1")
        version.get(use: getServerStatus(req:))
    }

    // GET / or GET /v1
        private func getServerStatus(req: Request) async throws -> APIServerStatus {
            return try await APIServerStatus.create(req: req)

        }


}
