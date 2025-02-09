//
//  Discovery.swift
//  DistributedSwiftDemo
//
//  Created by Steven Prichard on 2024-10-30.
//

import Foundation
import ServiceDiscovery
import DistributedCluster

extension App {
    enum Discovery {
        distributed actor EchoService {
            typealias ActorSystem = ClusterSystem
            
            @ActorID.Metadata(\.receptionID)
            var receptionID: String
            
            private let greetingService: GreetingService
            
            init(
                greetingService: GreetingService,
                actorSystem: ActorSystem
            ) async {
                self.actorSystem = actorSystem
                self.greetingService = greetingService
                self.receptionID = "*"
                
                await actorSystem.receptionist.checkIn(self)
            }
            
            distributed func echo(_ name: String) async throws -> String {
                let greeting = try await greetingService.greet(name: name)
                return "[ECHO]: \(greeting) - (from node: \(self.id.node), id: \(self.id.detailedDescription))"
            }
        }
        
        distributed actor GreetingService {
            typealias ActorSystem = ClusterSystem
            
            @ActorID.Metadata(\.receptionID)
            var receptionID: String
            
            private let greeting: String = "Hello, "
            
            init(actorSystem: ActorSystem) async {
                self.actorSystem = actorSystem
                self.receptionID = "*"
                
                await actorSystem.receptionist.checkIn(self)
            }
            
            distributed func greet(name: String) async throws -> String {
                return "\(greeting) \(name) - (from node: \(self.id.node), id: \(self.id.detailedDescription))"
            }
        }
        
        static func createNode(_ name: String) async -> ClusterSystem {
            let system = await ClusterSystem(name) { setting in
                setting.endpoint.port = .random(in: 4000..<5000)
                setting.autoLeaderElection = .lowestReachable(minNumberOfMembers: 1)
            }
                        
            return system
        }
        
        static func createServices(count: Int, with actorSystem: ClusterSystem) async -> [EchoService] {
            var services: [EchoService] = []
            for _ in 0..<count {
                let e = await EchoService(
                    greetingService: GreetingService(actorSystem: actorSystem),
                    actorSystem: actorSystem
                )
                services.append(e)
            }
            
            return services
        }
        
        static func createGreetingServices(count: Int, with actorSystem: ClusterSystem) async -> [GreetingService] {
            var services: [GreetingService] = []
            for _ in 0..<count {
                let e = await GreetingService(actorSystem: actorSystem)
                services.append(e)
            }
            
            return services
        }
                        
        static func runServiceDiscovery() async throws {
            let node1 = await createNode("Node-1")
            let node2 = await createNode("Node-2")
            let node3 = await createNode("Node-3")
            
            let root = await ClusterSystem("Root")
            root.cluster.join(endpoint: node1.cluster.endpoint)
            root.cluster.join(endpoint: node2.cluster.endpoint)
            root.cluster.join(endpoint: node3.cluster.endpoint)
            let cluster = [root, node1, node2, node3]
            
            let echoServices = await createServices(count: 3, with: node1)
            let moreServices = await createServices(count: 5, with: node2)
            let andMoreServices = await createServices(count: 3, with: node3)
            let andEvenMoreServices = await createServices(count: 10, with: root)
            
            Task {
                for try await echoActor in await root.receptionist.listing(of: EchoService.self) {
                    root.log.notice("🌎 Discovered \(echoActor.id) from \(echoActor.id.node)")
                }
            }
            
            print("ℹ️ Wait for cluster to stabilize...")
            try await MultiNodeCluster.ensureCluster(cluster, within: .seconds(10))
            print("✅ Cluster running!")
            
            startWorking(echoServices + moreServices + andMoreServices + andEvenMoreServices)
            try await root.terminated
        }
        
        static func startWorking(_ services: [EchoService]) {
            Task {
                while true {
                    try await Task.sleep(for: .seconds(3))
                    guard let service = services.randomElement() else { continue }
                    let response = try await service.echo("Request \(Int.random(in: 0...1000))")
                    print(response)
                }
            }
        }
    }
}

extension DistributedReception.Key {
    static var service1: DistributedReception.Key<App.Worker> {
        "service-1"
    }
}

extension HostPort: @unchecked @retroactive Sendable {}
