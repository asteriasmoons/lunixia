//
// JournalAnalysisService.swift
// Lystaria
//

import Foundation

struct JournalAnalysisResponse: Decodable {
    let themes: [String]
    let mood: String
    let reflection: String
    let dateKey: String
    let cached: Bool
}

private struct JournalAnalysisRequest: Encodable {
    struct EntryPayload: Encodable {
        let title: String
        let body: String
    }
    let userId: String
    let bookId: String
    let entries: [EntryPayload]
}

final class JournalAnalysisService {

    static let shared = JournalAnalysisService()
    private init() {}

    private let baseURL = "https://lystaria-api.fly.dev"

    func fetchAnalysis(userId: String, bookId: String, dateKey: String) async throws -> JournalAnalysisResponse? {
        guard var components = URLComponents(string: "\(baseURL)/api/journal/analyze") else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "bookId", value: bookId),
            URLQueryItem(name: "dateKey", value: dateKey)
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard http.statusCode == 200 else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "JournalAnalysisService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: text]
            )
        }

        let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let exists = raw?["exists"] as? Bool, exists else {
            return nil
        }

        return try JSONDecoder().decode(JournalAnalysisResponse.self, from: data)
    }

    func fetchAnalysisDates(userId: String, bookId: String) async throws -> [String] {
        guard var components = URLComponents(string: "\(baseURL)/api/journal/analyze/dates") else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "bookId", value: bookId)
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard http.statusCode == 200 else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "JournalAnalysisService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: text]
            )
        }

        struct DatesResponse: Decodable { let dates: [String] }
        let decoded = try JSONDecoder().decode(DatesResponse.self, from: data)
        return decoded.dates
    }

    func fetchTodayAnalysis(userId: String) async throws -> JournalAnalysisResponse? {
        guard var components = URLComponents(string: "\(baseURL)/api/journal/analyze") else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "userId", value: userId)
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard http.statusCode == 200 else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "JournalAnalysisService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: text]
            )
        }

        let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let exists = raw?["exists"] as? Bool, exists else {
            return nil
        }

        return try JSONDecoder().decode(JournalAnalysisResponse.self, from: data)
    }

    func analyze(
        userId: String,
        bookId: String,
        entries: [JournalEntry]
    ) async throws -> JournalAnalysisResponse {
        guard !entries.isEmpty else {
            throw NSError(
                domain: "JournalAnalysisService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No entries to analyze for today."]
            )
        }

        guard let url = URL(string: "\(baseURL)/api/journal/analyze") else {
            throw URLError(.badURL)
        }

        let payloads = entries.map { entry -> JournalAnalysisRequest.EntryPayload in
            let blockText = entry.sortedBlocks
                .compactMap { block -> String? in
                    let t = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    return t.isEmpty ? nil : t
                }
                .joined(separator: "\n")
            let body = blockText.isEmpty ? entry.body : blockText
            return JournalAnalysisRequest.EntryPayload(
                title: entry.title.isEmpty ? "Untitled" : entry.title,
                body: body
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            JournalAnalysisRequest(userId: userId, bookId: bookId, entries: payloads)
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard http.statusCode == 200 else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "JournalAnalysisService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: text]
            )
        }

        return try JSONDecoder().decode(JournalAnalysisResponse.self, from: data)
    }
}
