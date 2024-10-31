//
//  Distributed.swift
//  DistributedSwiftDemo
//
//  Created by Steven Prichard on 2024-10-23.
//
import MLX
import MLXLLM
import Distributed
import DistributedCluster


extension App {
    enum Distributed {
        typealias DefaultActorSystem = LocalTestingDistributedActorSystem

        static func runDistributedLLM() async throws {
            let configuration = LLM.defaultConfiguration
            let generationParameters = LLM.defaultGenerationParameters
            
            let system = DefaultActorSystem()
            let loader = Distributed.ModelLoader()
            
            let model = try await loader.loadModel(configuration: configuration)
            
            let tokenizer = Tokenizer(
                system: system,
                configuration: configuration,
                parameters: generationParameters,
                model: model
            )
            
            let promptGenerator = PromptGenerator(
                system: system,
                model: model,
                configuration: configuration,
                parameters: generationParameters
            )
                        
            let prompt = "Hello, world!"
            let tokens = try await tokenizer.tokenize(prompt: prompt)
            let response = try await promptGenerator.generate(promptTokens: tokens)
            print("ℹ️ Response: \n \(response)")
            print("✅ Done!")
        }
        
        actor ModelLoader {
            typealias CacheKey = String
            var loadedModels: [CacheKey: LLM.Model] = [:]
            
            func loadModel(configuration: ModelConfiguration) async throws -> ModelContainer {
                guard let model = getCachedModel(by: configuration.name) else {
                    let loadedModel = try await MLXLLM.loadModelContainer(configuration: configuration) { progress in
                        print("Downloading \(configuration.name): \(Int(progress.fractionCompleted * 100))%")
                    }
                    updateCache(loadedModel, for: configuration.name)
                    return loadedModel
                }
                
                return model
            }
            
            private func getCachedModel(by key: CacheKey) -> ModelContainer? {
                loadedModels[key]
            }
            
            private func updateCache(_ model: ModelContainer, for key: CacheKey) {
                loadedModels[key] = model
            }
        }
        
        // TODO: Make Distributed
        distributed actor PromptGenerator {
            typealias ActorSystem = Distributed.DefaultActorSystem
            typealias SerializationRequirement = any Codable
            
            let model: LLM.Model
            let configuration: ModelConfiguration
            let parameters: GenerateParameters
            private var currentTask: Task<GenerateResult, Never>?
            
            init(
                system: ActorSystem,
                model: LLM.Model,
                configuration: ModelConfiguration,
                parameters: GenerateParameters
            ) {
                self.actorSystem = system
                self.model = model
                self.configuration = configuration
                self.parameters = parameters
            }

            distributed func generate(
                promptTokens: [Int]
            ) async -> String {
                // TODO: Add prompt cache
                if let currentTask {
                    let result = await currentTask.value
                    return result.output
                }
                
                // By putting work in detached task, we allow the work to be performed on the
                // actors executor, allowing the work to have access to local values of the actor.
                let generationTask = Task { [configuration, parameters] in
                    return await model.perform { model, tokenizer in
                        MLXLLM.generate(
                            promptTokens: promptTokens,
                            parameters: parameters,
                            model: model,
                            tokenizer: tokenizer,
                            extraEOSTokens: configuration.extraEOSTokens
                        ) { tokens in
                            
                            return .more
                        }
                    }
                }

                let result = await generationTask.value
                print("ℹ️ \(result.summary())")
                return result.output
            }
            
            private func fireTask() {
                
            }
        }

        distributed actor Tokenizer {
            typealias ActorSystem = Distributed.DefaultActorSystem
            typealias SerializationRequirement = any Codable
            
            let configuration: ModelConfiguration
            let parameters: GenerateParameters
            let model: LLM.Model

            init(
                system: ActorSystem,
                configuration: ModelConfiguration,
                parameters: GenerateParameters,
                model: LLM.Model
            ) {
                self.actorSystem = system
                self.configuration = configuration
                self.parameters = parameters
                self.model = model
            }

            distributed func tokenize(
                prompt: String
            ) async -> [Int] {
                let prompt = configuration.prepare(prompt: prompt)

                return await model.perform { _, tokenizer in
                    return tokenizer.encode(text: prompt)
                }
            }
        }
    }
}
