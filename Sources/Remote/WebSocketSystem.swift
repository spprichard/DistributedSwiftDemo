//
//  Server.swift
//  DistributedSwiftDemo
//
//  Created by Steven Prichard on 2024-10-29.
//


import Foundation
import Distributed
import DistributedCluster

extension App {
    distributed actor PingService {
        typealias ActorSystem = WebSocketActorSystem
        typealias SerializationRequirement = any Codable
                        
        init(actorSystem: ActorSystem) {
            self.actorSystem = actorSystem
        }
        
        @Sendable
        distributed func ping() async throws -> String {
            print("ℹ️ [PING] Pinging... - (from Host: \(self.actorSystem.host), id: \(self.id))")
            return "Ping"
        }
    }
    
    distributed actor PongService {
        typealias ActorSystem = WebSocketActorSystem
        typealias SerializationRequirement = any Codable
        
        init(actorSystem: ActorSystem) {
            self.actorSystem = actorSystem
        }
        
        @Sendable
        distributed func pong() async throws -> String {
            print("ℹ️ [PONG] Ponging... - (from Host: \(self.actorSystem.host), id: \(self.id))")
            return "Pong"
        }
    }
    
    
    enum WebSocketSystem {
        distributed actor Client {
            typealias ActorSystem = WebSocketActorSystem
            typealias SerializationRequirement = any Codable
            
            enum Errors: Error {
                case unableToResolvePingService
                case unableToResolvePongService
            }
            
            let ping: PingService
            let pong: PongService
            
            init(actorSystem: ActorSystem) throws {
                self.actorSystem = actorSystem
                self.ping = PingService(actorSystem: actorSystem)
                self.pong = PongService(actorSystem: actorSystem)
            }

            distributed func pingPong() async throws -> String {
                let ping = try await ping.ping()
                let pong = try await pong.pong()
                return "[PING-PONG] \(ping) -> \(pong)"
            }   
        }
        
        public static func start(on bindPort: Int) {
            Task {
                try await runSystem(on: bindPort)
            }
        }
        
        private static func runSystem(on port: Int) async throws {
            let system = try WebSocketActorSystem(mode: .serverOnly(host: "localhost", port: port))
            
            system.registerOnDemandResolveHandler { id in
                guard let resolved = system.resolveAny(id: id) else {
                    let new = system.makeActorWithID(id) {
                        return PingPongService(actorSystem: system)
                    }
                    
                    return new
                }
                
                return resolved
            }

            print("========================================================")
            print("=== TicTacFish Server Running on: ws://\(system.host):\(system.port) ==")
            print("========================================================")
        }
        
        distributed actor PingPongService {
            typealias ActorSystem = WebSocketActorSystem
            typealias SerializationRequirement = any Codable
            
            private let ping: PingService
            private let pong: PongService
            
            init(actorSystem: ActorSystem) {
                self.actorSystem = actorSystem
                self.ping = PingService(actorSystem: actorSystem)
                self.pong = PongService(actorSystem: actorSystem)
            }
            
            distributed func pingPong() async throws -> String {
                let pingResult = try await ping.ping()
                let pongResult = try await pong.pong()
                return "🔁 [PING-PONG] \(pingResult) \(pongResult)"
            }
        }
    }
}

