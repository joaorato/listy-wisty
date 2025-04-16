//
//  AIModels.swift
//  ListyWisty
//
//  Created by João Rato on 16/04/2025.
//

import Foundation

struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Encodable {
    let temperature: Double?
    let maxOutputTokens: Int?
}

struct GeminiResponse: Decodable {
    let candidates:[GeminiCandidate]?
    let promptFeedback: GeminiPromptFeedback?
}

struct GeminiCandidate: Decodable {
    let content: GeminiContent?
    let finishReason: String? // e.g., "STOP", "MAX_TOKENS", "SAFETY", "RECITATION", "OTHER"
    // safetyRatings can be added here if needed
}

struct GeminiPromptFeedback: Decodable {
    let blockReason: String? // e.g., "SAFETY", "OTHER"
    // safetyRatings can be added here if needed
}

// Gemini Error Structure
struct GeminiErrorResponse: Decodable {
    struct GeminiErrorDetail: Decodable {
        let code: Int?
        let message: String?
        let status: String? // e.g., "INVALID_ARGUMENT"
    }
    let error: GeminiErrorDetail?
}
