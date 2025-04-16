//
//  AIService.swift
//  ListyWisty
//
//  Created by João Rato on 16/04/2025.
//


import Foundation

// Structure matching the expected JSON output from the LLM
struct ParsedItem: Decodable, Identifiable { // Identifiable might be useful later
    let id = UUID() // Local ID for potential UI updates before saving
    let name: String
    let quantity: Int? // LLM should return numeric quantity
    let unit: String?
    
    // Define CodingKeys for properties expected FROM the JSON ONLY
    enum CodingKeys: String, CodingKey {
        case name, quantity, unit // Exclude 'id'
    }

    // Custom Decodable initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode the properties that ARE in the JSON
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) // Use decodeIfPresent for optionals
        unit = try container.decodeIfPresent(String.self, forKey: .unit)     // Use decodeIfPresent for optionals

        // 'id' is NOT decoded from JSON. It automatically gets its
        // default UUID() value when the struct instance is created
        // after this initializer successfully completes.
    }

    // Optional: Add a non-decoding initializer if needed for testing/manual creation
    init(testName: String, quantity: Int? = 1, unit: String? = nil) {
         self.name = testName
         self.quantity = quantity
         self.unit = unit
         // id gets default value
    }
}

// Structure for the request body sent to your backend proxy
struct ParseRequest: Encodable {
    let text: String
    let listType: String // Send list type for context (e.g., "shopping", "task")
}

// Define potential errors
enum AIServiceError: Error {
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
    case invalidResponseFormat
    case apiKeyMissing // Or configuration error
    case backendProxyError(String) // Error message from your proxy
    case llmError(String)
}

// The service class
class AIService {
    // URL for the LLM Provider API
    private let geminiAPIEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    // URL of YOUR backend proxy function (replace with actual URL)
    // Ideally, load this from a configuration file or environment variables
    private let backendProxyURL = URL(string: "YOUR_BACKEND_PROXY_ENDPOINT_HERE")!
    private let llmProviderAPIKey: String? = {
        #if DEBUG
        // --- WARNING: DEVELOPMENT ONLY ---
        // Replace with a TEST key with STRICT usage limits.
        // This will be included in DEBUG builds ONLY.
        // DO NOT SHIP THIS TO TESTFLIGHT OR APP STORE.
        let debugKey = "YOUR_API_KEY"
        // Basic check to prevent accidental commit of placeholder
        return debugKey.contains("YOUR_GEMINI") ? nil : debugKey
        #else
        // In Release builds, we rely SOLELY on the backend proxy.
        return nil
        #endif
    }()
    
    // The main function the ViewModel will call
    func parseItems(from text: String, listType: ListType) async throws -> [ParsedItem] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return [] // Return empty if input is empty
        }
        
        #if DEBUG
        // --- DEBUG PATH: Direct API Call ---
        guard let apiKey = llmProviderAPIKey else {
            print("❌ AIService [DEBUG]: Gemini API Key missing or placeholder detected. Cannot make direct call.")
            print("   Ensure you've replaced 'YOUR_GEMINI_API_KEY_HERE' in AIService.swift")
            throw AIServiceError.apiKeyMissing
        }
        print("⚠️ AIService [DEBUG]: Making DIRECT call to Google Gemini (REMOVE BEFORE RELEASE)")
        // *** CHANGE: Call the new Gemini helper ***
        return try await makeDirectLLMCall(text: text, apiKey: apiKey, listType: listType)
        #else
        // --- RELEASE PATH: Use Backend Proxy ---
        print("🤖 AIService [RELEASE]: Sending text to proxy: \"\(text)\"")
        
        let requestBody = ParseRequest(text: text, listType: listType.rawValue)
        var request = URLRequest(url: backendProxyURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add authentication if your proxy requires it (e.g., a simple secret header)
        // request.addValue("YOUR_PROXY_SECRET", forHTTPHeaderField: "X-Proxy-Secret")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("❌ AIService: Error encoding request body: \(error)")
            throw AIServiceError.decodingError(error) // Or a more specific internal error
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ AIService: Invalid response from server.")
                throw AIServiceError.invalidResponseFormat
            }

            print("🤖 AIService: Received response with status code: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to decode an error message from the proxy if possible
                let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
                print("❌ AIService: Server error \(httpResponse.statusCode). Body: \(errorBody)")
                throw AIServiceError.serverError(statusCode: httpResponse.statusCode)
            }

            // Decode the successful response ([ParsedItem])
            do {
                let parsedItems = try JSONDecoder().decode([ParsedItem].self, from: data)
                print("✅ AIService: Successfully decoded \(parsedItems.count) items.")
                // --- DEBUG: Print decoded items ---
                 parsedItems.forEach { item in
                     print("   - Name: \(item.name), Qty: \(item.quantity ?? 1), Unit: \(item.unit ?? "nil")")
                 }
                // --- End Debug ---
                return parsedItems
            } catch {
                print("❌ AIService: Error decoding successful response: \(error)")
                print("   Raw response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode data")")
                throw AIServiceError.decodingError(error)
            }

        } catch let error as AIServiceError {
             throw error // Re-throw known AI service errors
        } catch {
             print("❌ AIService: Network or other error: \(error)")
             throw AIServiceError.networkError(error)
        }
        #endif
    }
    
    // --- Placeholder for direct call implementation ---
    #if DEBUG
    private func makeDirectLLMCall(text: String, apiKey: String, listType: ListType) async throws -> [ParsedItem] {
        // 1. Construct the URL with API Key
        guard var urlComponents = URLComponents(string: geminiAPIEndpoint) else {
            fatalError("Invalid Gemini API Endpoint URL string.") // Should not happen
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let requestURL = urlComponents.url else {
             throw AIServiceError.apiKeyMissing // Or another configuration error
        }
        print("   [DEBUG] Request URL: \(requestURL.absoluteString)")
        
        // 2. Construct the Prompt
         let systemInstruction = """
         You are an intelligent assistant parsing items for a list app. The user is adding items to a '\(listType.rawValue)' list.
         Parse the user's text into distinct items. For each item, identify the name, quantity, and unit.
         The user may use other languages other than English, specifically European Portuguese.

         Instructions:
         1. Separate items based on commas, the word "and", or newlines.
         2. Identify the item name. Clean it up slightly (e.g., first letter uppercase, trim whitespace).
         3. Identify the quantity. Convert common words like 'dozen' to 12, 'pair' to 2. If no quantity is mentioned, default to 1. Ensure quantity is an integer.
         4. Identify common units associated with the quantity (e.g., kg, g, lbs, oz, liters, mL, gallon, pack, box, bottle, can, bag, loaf, bunch). If no unit is specified or applicable, the unit should be null.
         5. Structure the output ONLY as a valid JSON array of objects. Each object MUST have the keys "name" (string), "quantity" (integer, default 1), and "unit" (string or null).
         6. IMPORTANT: Do not include any introductory text, explanations, markdown formatting (like ```json ... ```), or anything else before or after the JSON array. Only the raw JSON array is allowed. Failure to comply will result in an error.
         """
        
        // Gemini prefers prompt instructions potentially followed by user input in parts
        // Combine instruction and user text into a single part for simplicity here
        let combinedPrompt = "\(systemInstruction)\n\nParse the following text:\n\(text)"
        
        
        // 3. Construct the Request Body
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(parts: [GeminiPart(text: combinedPrompt)])
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.1, // Low temperature for deterministic JSON
                maxOutputTokens: 1024 // Adjust as needed
                // responseMimeType: "application/json" // Try adding this if Gemini supports it for your model
            )
        )
        
        // 4. Create URLRequest
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // NO Bearer token needed for Gemini key in URL
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            if let body = request.httpBody, let jsonString = String(data: body, encoding: .utf8) {
                 print("   [DEBUG] Gemini Request Body: \(jsonString)")
            }
        } catch {
            print("❌ AIService [Debug]: Error encoding Gemini request body: \(error)")
            throw AIServiceError.decodingError(error)
        }
        
        // 5. Perform the API Call
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ AIService [Debug]: Invalid response from Google AI.")
                throw AIServiceError.invalidResponseFormat
            }

            print("   [DEBUG] Gemini Response Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                 print("   [DEBUG] Gemini Raw Response: \(responseString)")
            }

            // 6. Handle Response Status and Decode
            // Gemini often returns 200 OK even for errors like API key issues,
            // so we need to decode the body *first* to check for errors or blocks.

            let geminiResponse: GeminiResponse
            do {
                 geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            } catch {
                 // Check if it's a structured error response from Google *before* failing decode
                 if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data),
                     let detail = errorResponse.error {
                     let errorMessage = "Gemini API Error \(detail.code ?? httpResponse.statusCode): \(detail.message ?? "Unknown Error") (\(detail.status ?? "N/A"))"
                     print("❌ AIService [Debug]: \(errorMessage)")
                     throw AIServiceError.serverError(statusCode: detail.code ?? httpResponse.statusCode, message: errorMessage)
                 } else {
                     // If it's not a known Gemini error struct, then it's a decoding failure
                     print("❌ AIService [Debug]: Failed to decode Gemini response structure: \(error)")
                     throw AIServiceError.decodingError(error)
                 }
            }

            // 7. Check for Blocking Reasons
            if let blockReason = geminiResponse.promptFeedback?.blockReason {
                 let message = "Request blocked by Gemini due to: \(blockReason)"
                 print("❌ AIService [Debug]: \(message)")
                 throw AIServiceError.llmError(message) // Use llmError for content issues
            }
            if let finishReason = geminiResponse.candidates?.first?.finishReason, finishReason != "STOP" && finishReason != "MAX_TOKENS" {
                 let message = "Gemini response finished unexpectedly: \(finishReason)"
                 print("❌ AIService [Debug]: \(message)")
                 throw AIServiceError.llmError(message) // Or a more specific error if needed
            }


            // 8. Extract and Decode the Content JSON
            guard let contentText = geminiResponse.candidates?.first?.content?.parts.first?.text else {
                // Check if maybe the response was empty but successful (e.g., safety block but not reported?)
                 if httpResponse.statusCode == 200 {
                      print("⚠️ AIService [Debug]: Gemini response successful (200) but no content text found.")
                       throw AIServiceError.llmError("AI returned an empty response.")
                 } else {
                      // Should have been caught by error decoding earlier, but just in case
                      print("❌ AIService [Debug]: No content found in Gemini response and status was \(httpResponse.statusCode).")
                       throw AIServiceError.llmError("AI response was empty or missing content.")
                 }
            }

            print("   [DEBUG] Extracted content from Gemini: \(contentText)")

            guard let contentData = contentText.data(using: .utf8) else {
                 print("❌ AIService [Debug]: Could not convert Gemini content string to Data.")
                 throw AIServiceError.llmError("Could not process AI content.")
            }

            do {
                let parsedItems = try JSONDecoder().decode([ParsedItem].self, from: contentData)
                print("✅ AIService [Debug]: Successfully decoded \(parsedItems.count) items from Gemini content.")
                 parsedItems.forEach { item in
                   print("      - Name: \(item.name), Qty: \(item.quantity ?? 1), Unit: \(item.unit ?? "nil")")
                }
                return parsedItems
            } catch {
                print("❌ AIService [Debug]: Failed to decode the JSON content ('\(contentText)') provided by Gemini into [ParsedItem]: \(error)")
                throw AIServiceError.llmError("AI returned invalid JSON format. Content: \(contentText)")
            }

        } catch let error as AIServiceError {
             throw error // Re-throw known AI service errors
        } catch {
             print("❌ AIService [Debug]: Network or other error during direct Gemini call: \(error)")
             throw AIServiceError.networkError(error)
        }
    }
    
    #endif
}
