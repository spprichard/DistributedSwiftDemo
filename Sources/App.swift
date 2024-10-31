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
        // try await Distributed.runDistributedLLM()
        // try await MultiNodeCluster.runMultiNodeCluster()
        //try await Server.run()
        try await Discovery.runServiceDiscovery()
    }
}




