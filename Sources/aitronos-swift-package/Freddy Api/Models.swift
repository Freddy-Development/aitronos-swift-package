//
//  Models.swift
//  aitronos
//
//  Created by Phillip Loacker on 21.11.2024.
//

public enum FreddyModel: String, CaseIterable, Codable {
    case textGen15Turbo = "ftg-1.5"
    case textGen15Basic = "ftg-1.5-basic"
    case textGen16Advanced = "ftg-1.6"
    case textGen16Basic = "ftg-1.6-basic"
    case textGen10Turbo = "ftg-1.0"
    case textGen10Basic = "ftg-1.0-basic"
    case textGen05 = "ftg-0.5"
    case imageGen = "fig"
    case imageGenHD = "fig-hd"
    case textToVoice = "fttv"
    case textToVoiceHD = "fttv-hd"
    case voiceToText = "fvtt"
    case textModerationLatest = "ftm-latest"
    case textModerationStable = "ftm-stable"

    public var title: String {
        switch self {
        case .textGen15Turbo: return "Freddy Text GEN 1.5 Turbo"
        case .textGen15Basic: return "Freddy Text GEN 1.5"
        case .textGen16Advanced: return "Freddy Text GEN 1.6 Advanced"
        case .textGen16Basic: return "Freddy Text GEN 1.6"
        case .textGen10Turbo: return "Freddy Text GEN 1.0 Turbo"
        case .textGen10Basic: return "Freddy Text GEN 1.0 Basic"
        case .textGen05: return "Freddy Text GEN 0.5"
        case .imageGen: return "Freddy Image GEN"
        case .imageGenHD: return "Freddy Image GEN HD"
        case .textToVoice: return "Freddy Text-To-Voice"
        case .textToVoiceHD: return "Freddy Text-To-Voice HD"
        case .voiceToText: return "Freddy Voice-To-Text"
        case .textModerationLatest: return "Freddy Text Moderation - Latest"
        case .textModerationStable: return "Freddy Text Moderation - Stable"
        }
    }

    public var description: String {
        switch self {
        case .textGen15Turbo:
            return "Our high-intelligence flagship model for complex, multi-step tasks. GPT-4o is cheaper and faster than GPT-4 Turbo."
        case .textGen15Basic:
            return "Our affordable and intelligent small model for fast, lightweight tasks. GPT-4o mini is cheaper and more capable than GPT-3.5 Turbo."
        case .textGen16Advanced:
            return "Language models trained with reinforcement learning to perform complex reasoning. This reasoning model is designed to solve hard problems across domains."
        case .textGen16Basic:
            return "Language models trained with reinforcement learning to perform complex reasoning. This reasoning model is faster and cheaper reasoning model particularly good at coding, math, and science."
        case .textGen10Turbo:
            return "The previous set of high-intelligence models. The latest GPT-4 Turbo model with vision capabilities. Vision requests can now use JSON mode and function calling."
        case .textGen10Basic:
            return "The previous set of high-intelligence models."
        case .textGen05:
            return "A fast, inexpensive model for simple tasks."
        case .imageGen:
            return "A model that can generate and edit images given a natural language prompt."
        case .imageGenHD:
            return "A model that can generate and edit images given a natural language prompt."
        case .textToVoice:
            return "A set of models that can convert text into natural sounding spoken audio, optimized for speed."
        case .textToVoiceHD:
            return "A set of models that can convert text into natural sounding spoken audio, optimized for quality."
        case .voiceToText:
            return "A model that can convert audio into text."
        case .textModerationLatest:
            return "A fine-tuned model that can detect whether text may be sensitive or unsafe."
        case .textModerationStable:
            return "A fine-tuned model that can detect whether text may be sensitive or unsafe."
        }
    }
}
