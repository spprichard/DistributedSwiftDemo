import Hub
import MLX
import MLXLLM
import Foundation
import Distributed
import DistributedCluster

@main
struct App {
    static func main() async throws {
        // try await Clustered.runCluster()
        // try await LLM.runLLM()
         try await Distributed.runDistributedLLM()
        // try await MultiNodeCluster.runMultiNodeCluster()
//        try await runWebSocketExample()
        // try await Discovery.runServiceDiscovery()
    }
    
    static func runWebSocketExample() async throws {
        let systemPort = 9000
        WebSocketSystem.start(on: systemPort)
        
        let system = try WebSocketActorSystem(
            mode: .client(
                host: "localhost",
                port: systemPort
            )
        )
        
        let client = try WebSocketSystem.Client(actorSystem: system)
        let result = try await client.pingPong()
        print("✅ Done: \(result)" )
    }
    
    
}




