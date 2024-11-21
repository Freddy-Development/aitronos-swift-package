//
//  Models.swift
//  aitronos
//
//  Updated to include all models from the backend.
//

public enum FreddyModel: String, CaseIterable, Codable {
    case ftg15Turbo = "ftg-1.5"
    case ftg15Basic = "ftg-1.5-basic"
    case ftg16Advanced = "ftg-1.6"
    case ftg16Basic = "ftg-1.6-basic"
    case ftg10Turbo = "ftg-1.0"
    case ftg10Basic = "ftg-1.0-basic"
    case ftg05 = "ftg-0.5"
    case fig1024 = "fig-1024"
    case figHD1024x1792 = "fig-hd-1792"
    case figHD1024x1024 = "fig-hd-1024"
    case fttv = "fttv"
    case fttvHD = "fttv-hd"
    case fvtt = "fvtt"
    case ftmLatest = "ftm-latest"
    case ftmStable = "ftm-stable"

    public var title: String {
        switch self {
        case .ftg15Turbo: return "Freddy Text GEN 1.5 Turbo"
        case .ftg15Basic: return "Freddy Text GEN 1.5 Basic"
        case .ftg16Advanced: return "Freddy Text GEN 1.6 Advanced"
        case .ftg16Basic: return "Freddy Text GEN 1.6 Basic"
        case .ftg10Turbo: return "Freddy Text GEN 1.0 Turbo"
        case .ftg10Basic: return "Freddy Text GEN 1.0 Basic"
        case .ftg05: return "Freddy Text GEN 3.5 Turbo"
        case .fig1024: return "Freddy Image GEN (1024x1024)"
        case .figHD1024x1792: return "Freddy Image GEN HD (1024x1792)"
        case .figHD1024x1024: return "Freddy Image GEN HD (1024x1024)"
        case .fttv: return "Freddy Text-To-Voice"
        case .fttvHD: return "Freddy Text-To-Voice HD"
        case .fvtt: return "Freddy Voice-To-Text"
        case .ftmLatest: return "Freddy Text Moderation - Latest"
        case .ftmStable: return "Freddy Text Moderation - Stable"
        }
    }

    public var description: String {
        switch self {
        case .ftg15Turbo:
            return "Our high-intelligence flagship model for complex, multi-step tasks. GPT-4o is cheaper and faster than GPT-4 Turbo."
        case .ftg15Basic:
            return "Our affordable and intelligent small model for fast, lightweight tasks. GPT-4o mini is cheaper and more capable than GPT-3.5 Turbo."
        case .ftg16Advanced:
            return "Language models trained with reinforcement learning to perform complex reasoning. This reasoning model is designed to solve hard problems across domains."
        case .ftg16Basic:
            return "Language models trained with reinforcement learning to perform complex reasoning. This reasoning model is faster and cheaper reasoning model particularly good at coding, math, and science."
        case .ftg10Turbo:
            return "The previous set of high-intelligence models. The latest GPT-4 Turbo model with vision capabilities. Vision requests can now use JSON mode and function calling."
        case .ftg10Basic:
            return "The previous set of high-intelligence models."
        case .ftg05:
            return "A fast, inexpensive model for simple tasks."
        case .fig1024:
            return "A model that can generate and edit images given a natural language prompt."
        case .figHD1024x1792:
            return "A model that can generate and edit images given a natural language prompt with HD quality (1024x1792)."
        case .figHD1024x1024:
            return "A model that can generate and edit images given a natural language prompt with HD quality (1024x1024)."
        case .fttv:
            return "A set of models that can convert text into natural sounding spoken audio, optimized for speed."
        case .fttvHD:
            return "A set of models that can convert text into natural sounding spoken audio, optimized for quality."
        case .fvtt:
            return "A model that can convert audio into text."
        case .ftmLatest:
            return "A fine-tuned model that can detect whether text may be sensitive or unsafe."
        case .ftmStable:
            return "A fine-tuned model that can detect whether text may be sensitive or unsafe."
        }
    }
}
