//
//  AzureTranslator.swift
//  Kate Assignment 3 App
//
//  Created by user919256 on 11/14/19.
//  Copyright © 2019 user919256. All rights reserved.
//

import Foundation


private typealias LanguageCode = String

private struct Language {
    let language: LanguageCode
    let score: Float
}

extension Language: Codable {}

private struct Translation {
    let text: String
    let to: LanguageCode
}

extension Translation: Codable {}

private struct TranslateResult {
    let detectedLanguage: Language?
    let translations: [Translation]
}

extension TranslateResult: Codable {}

// https://docs.microsoft.com/en-us/azure/cognitive-services/translator/reference/v3-0-translate?tabs=curl
private func getToken(_ key: String, completion block: @escaping (Data?, URLResponse?, Error?) -> Void) {

    var request = URLRequest(url: URL(string: "https://api.cognitive.microsoft.com/sts/v1.0/issueToken")!)
    request.httpMethod = "POST"
    request.addValue(key, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")

    let session = URLSession.shared
    let task = session.dataTask(with: request, completionHandler: block)

    task.resume()
}

private func msTranslate(_ token: String, translate text: String, toLang lang: String, completion block: @escaping (Data?, URLResponse?, Error?) -> Void) {

    var c = URLComponents(string: "https://api.cognitive.microsofttranslator.com/translate")

    c?.queryItems = [
        URLQueryItem(name: "api-version", value: "3.0"),
        URLQueryItem(name: "to", value: lang)
    ]

    guard let url = c?.url else {
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    request.httpBody = """
        [{"Text":"\(text)"}]
        """.data(using: .utf8)

    let session = URLSession.shared
    let task = session.dataTask(with: request, completionHandler: block)

    task.resume()
}

private func extract(_ json: Data) throws -> String? {
    let results = try JSONDecoder().decode([TranslateResult].self, from: json)
    return results.first?.translations.first?.text
}

enum AzureMicrosoftTranslatorError: Error {
    case tokenParseError
    case textParseError
    case apiKeyIsNotInitialized
}

@objcMembers
class AzureMicrosoftTranslator: NSObject {

    static let sharedTranslator = AzureMicrosoftTranslator()

    var key: String?

    func translate(_ text: String, toLang lang: String, completion block: @escaping (String?, URLResponse?, Error?) -> Void) {

        guard let key = key else {
            block(nil, nil, AzureMicrosoftTranslatorError.apiKeyIsNotInitialized as NSError)
            return
        }

        getToken(key) { (data, response, error) in
            if let error = error {
                block(nil, response, error)
                return
            }

            guard let data = data, let token = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String? else {
                block(nil, response, AzureMicrosoftTranslatorError.tokenParseError as NSError)
                return
            }

            msTranslate(token, translate: text, toLang: lang) { (data, response, error) in

                if let error = error {
                    block(nil, response, error)
                    return
                }

                guard let data = data,
                    let result = try? extract(data) else {

                        block(nil, response, AzureMicrosoftTranslatorError.textParseError as NSError)
                        return
                }

                block(result, response, nil)
            }
        }
    }
}
