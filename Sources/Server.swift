//
//  Server.swift
//  DistributedSwiftDemo
//
//  Created by Steven Prichard on 2024-10-29.
//

import Hummingbird
import DistributedCluster

extension App {
    distributed actor Thing1 {
        typealias ActorSystem = ClusterSystem
        typealias SerializationRequirement = Codable
        
        static func == (lhs: App.Thing1, rhs: App.Thing1) -> Bool {
            lhs.actorSystem.name == rhs.actorSystem.name
        }
        
        distributed func greet(_ name: String) -> String {
            "Thing 1 says - Hello, \(name)"
        }
    }
    
    distributed actor Thing2 {
        typealias ActorSystem = ClusterSystem
        typealias SerializationRequirement = Codable
        
        static func == (lhs: App.Thing2, rhs: App.Thing2) -> Bool {
            lhs.actorSystem.name == rhs.actorSystem.name
        }
        
        distributed func greet(_ name: String) -> String {
            "Thing 2 says - Hello, \(name)"
        }
    }
    
    
    enum Server {
        // how does a node discover the cluster system?
        static func run() async throws {
            let system = await ClusterSystem("Cluster")
            let thing1 = Thing1(actorSystem: system)
            let thing2 = Thing2(actorSystem: system)
            
            Task {
                while true {
                    let thing1Response = try await thing1.greet("Marco")
                    system.log.info("ℹ️ Response: \(thing1Response)")
                    
                    let thing2Response = try await thing2.greet("Polo")
                    system.log.info("ℹ️ Response: \(thing2Response)")
                    
                    try await Task.sleep(for: .seconds(1))
                }
            }
            
            
            try await system.terminated
        }
        
        private func runExampleServer() async throws {
            let router = Router()
            
            router.get("/") { request, context  -> String in
                "Hello, World!"
            }
            
            let app = Application(
                router: router,
                configuration: .init(
                    address: .hostname("127.0.0.1", port: 9090)
                )
                
            )
            
            
            
            try await app.run()
        }
    }
}
