//
//  LLM.swift
//  DistributedSwiftDemo
//
//  Created by Steven Prichard on 2024-10-23.
//

import MLX
import MLXLLM

extension App {
    enum LLM {
        typealias Model = ModelContainer
        static let defaultConfiguration: ModelConfiguration = .llama3_2_1B_4bit
        static let defaultGenerationParameters: GenerateParameters = .init(
            temperature: 0.95,
            repetitionPenalty: 0.9
        )
        
        static func runLLM() async throws {
            // limit the buffer cache
            //MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
            let configuration: ModelConfiguration = defaultConfiguration
            let generationParameters = defaultGenerationParameters

            let modelLoader = ModelLoaderActor()
            let model = try await modelLoader.loadModel(configuration: configuration)

            let tokenizer = Tokenizer(
                configuration: configuration,
                parameters: generationParameters
            )

            let promptGenerator = PromptGenerator(
                model: model,
                parameters: generationParameters,
                configuration: configuration
            )

            let rawPrompt = "Hello, world!"
            let promptTokens = await tokenizer.tokenize(
                prompt: rawPrompt,
                container: model
            )

            await promptGenerator.generate(promptTokens: promptTokens)
        }
        
        actor ModelLoaderActor {
            typealias CacheKey = String
            var loadedModels: [CacheKey: Model] = [:]

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

        actor PromptGenerator {
            let model: ModelContainer
            let parameters: GenerateParameters
            let configuration: ModelConfiguration

            init(
                model: ModelContainer,
                parameters: GenerateParameters,
                configuration: ModelConfiguration
            ) {
                self.model = model
                self.parameters = parameters
                self.configuration = configuration
            }

            func generate(promptTokens: [Int]) async {
                let _ = await model.perform { model, tokenizer in
                    MLXLLM.generate(
                        promptTokens: promptTokens,
                        parameters: parameters,
                        model: model,
                        tokenizer: tokenizer,
                        extraEOSTokens: configuration.extraEOSTokens
                    ) { tokens in
                        let text = tokenizer.decode(tokens: tokens)
                        print(text)

                        return .more
                    }
                }
            }

        }

        actor Tokenizer {
            let configuration: ModelConfiguration
            let parameters: GenerateParameters

            init(configuration: ModelConfiguration, parameters: GenerateParameters) {
                self.configuration = configuration
                self.parameters = parameters
            }

            func tokenize(
                prompt: String,
                container: ModelContainer
            ) async -> [Int] {
                let prompt = configuration.prepare(prompt: prompt)

                return await container.perform { _, tokenizer in
                    return tokenizer.encode(text: prompt)
                }
            }
        }
    }
}
