//
//  Clustered.swift
//  DistributedSwiftDemo
//
//  Created by Steven Prichard on 2024-10-23.
//

import Distributed
import DistributedCluster

extension App {
    enum Clustered {
        enum Information {
            static let name = "LLM Inference System"
            static let host = "127.0.0.1"
            static let port = 7337
        }
                
        static func runCluster() async throws {
            // Create Actor System
            let system = await ClusterSystem(Information.name) { settings in
                settings.endpoint.host = Information.host
                settings.endpoint.port = Information.port
            }
            watchCluster(system)
            
            // Create Node for Tokenizer
            let tokenizerNode = createTokenizerNode()
            system.cluster.join(node: tokenizerNode)
            
            // Create Node for Model Response
             let modelNode = createModelNode()
            system.cluster.join(node: modelNode)
            
            try await system.terminated
        }
        
        static func createTokenizerNode() -> Cluster.Node {
            .init(
                systemName: Information.name,
                host: Information.host,
                port: Information.port,
                nid: .random()
            )
        }
        
        static func createModelNode() -> Cluster.Node {
            .init(
                systemName: Information.name,
                host: Information.host,
                port: Information.port,
                nid: .random()
            )
        }
        
        static func watchCluster(_ system: ClusterSystem) {
            Task {
                for await event in system.cluster.events {
                    switch event {
                        case .snapshot(let membership):
                            print("📸 snapshot Event: \(membership)")
                        case .membershipChange(let membershipChange):
                            print("🏘️ membershipChange Event: \(membershipChange)")
                        case .reachabilityChange(let reachabilityChange):
                            print("🌐 reachabilityChange Event: \(reachabilityChange)")
                        case .leadershipChange(let leadershipChange):
                            print("🙋‍♂️ leadershipChange Event: \(leadershipChange)")
                        default:
                            print("❓ Unknown Event...")
                    }
                }
            }
        }
    }
}
