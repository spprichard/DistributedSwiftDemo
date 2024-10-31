//
//  MultiNodeCluster.swift
//  DistributedSwiftDemo
//
//  Created by Steven Prichard on 2024-10-29.
//

import Foundation
import DistributedCluster

extension App {
    enum MultiNodeCluster {
        static func runMultiNodeCluster() async throws {
            let system1 = await ClusterSystem("System 1️⃣") { settings in
                settings.bindPort = 1111
            }
            
            let system2 = await ClusterSystem("System 2️⃣") { settings in
                settings.bindPort = 2222
            }
            
            let system3 = await ClusterSystem("System 3️⃣") { settings in
                settings.bindPort = 3333
            }
            
            let systems = [system1, system2, system3]
            print("~~~~~~~ started \(systems.count) actor systems ~~~~~~~")
            system1.cluster.join(endpoint: system2.cluster.endpoint)
            system1.cluster.join(endpoint: system3.cluster.endpoint)
            system3.cluster.join(endpoint: system2.cluster.endpoint)
            
            print("~~~~~~~ waiting for cluster to form... ~~~~~~~")
            try await ensureCluster(systems, within: .seconds(10))
            print("~~~~~~~ systems joined each other ~~~~~~~")
            
            let workerA1 = Worker(actorSystem: system1, workerID: 1)
            let workerA2 = Worker(actorSystem: system1, workerID: 2)
            let workerB1 = Worker(actorSystem: system2, workerID: 1)
            let workerC1 = Worker(actorSystem: system3, workerID: 1)
            let workerC2 = Worker(actorSystem: system3, workerID: 2)
            
            let workers = [
                workerA1,
                workerA2,
                workerB1,
                workerC1,
                workerC2,
            ]
            
            Task {
                print("~~~~~~~ 🔁 Starting Run Loop 🔁 ~~~~~~~")
                while true {
                    try await Task.sleep(for: .seconds(1))
                    if let randomWorker = workers.randomElement() {
                        print("ℹ️ Got random worker from system \(randomWorker.actorSystem.name)")
                        try await randomWorker.work()
                    }
                }
            }
            
            
            try await system1.terminated // if system1 creashes this would take down the whole cluster
        }
        
        static func ensureCluster(_ systems: [ClusterSystem], within: Duration) async throws {
            let nodes = Set(systems.map(\.settings.bindNode))

            try await withThrowingTaskGroup(of: Void.self) { group in
                for system in systems {
                    group.addTask {
                        try await system.cluster.waitFor(nodes, .up, within: within)
                    }
                }
                // loop explicitly to propagagte any error that might have been thrown
                for try await _ in group {}
            }
        }
        
        static func example() async throws {
            let system = await ClusterSystem("ReceptionistExamples")
            
            let boss = Boss(actorSystem: system)
            await system.receptionist.checkIn(boss, with: .boss)
            
            for i in 1...5 {
                let worker = Worker(actorSystem: system, workerID: i)
                await system.receptionist.checkIn(worker, with: .workers)
            }
            
            Task {
                Timer(timeInterval: 2, repeats: true) { _ in
                    Task {
                        for await worker in await system.receptionist.listing(of: .workers) {
                            print("ℹ️ Calling worker")
                            try await worker.work()
                        }
                    }
                }
            }

            try await system.terminated
        }
    }
    
    
    
    distributed actor Boss: LifecycleWatch {
        typealias ActorSystem = ClusterSystem
        var workers: WeakActorDictionary<Worker> = [:]
        
        var listingTask: Task<Void, Never>?
        
        deinit {
            listingTask?.cancel()
        }
        
        func findWorkers() async {
            guard listingTask == nil else {
                actorSystem.log.info("ℹ️ Already looking for workers")
                return
            }
            
            listingTask = Task {
                for await worker in await actorSystem.receptionist.listing(of: .workers) {
                    workers.insert(worker)
                }
            }
        }
        
        func terminated(actor id: DistributedCluster.ActorID) async {
            let _ = workers.removeActor(identifiedBy: id)
        }
    }
    
    distributed actor Worker {
        typealias ActorSystem = ClusterSystem
        var workerID: Int
        
        init(actorSystem: ActorSystem, workerID: Int) {
            self.actorSystem = actorSystem
            self.workerID = workerID
        }
        
        distributed func work() async {
            print("ℹ️ Worker: \(workerID) - Work work work...")
        }
    }
}

extension DistributedReception.Key {
    static var workers: DistributedReception.Key<App.Worker> {
        "workers"
    }
    
    static var boss: DistributedReception.Key<App.Boss> {
        "boss"
    }
}
