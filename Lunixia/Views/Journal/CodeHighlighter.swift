//
//  CodeHighlighter.swift
//  Lystaria
//
//  Created by Asteria Moon
//

import UIKit

// MARK: - Languages

enum CodeLanguage: String, CaseIterable, Identifiable {
    case plainText  = "Plain Text"
    case swift      = "Swift"
    case python     = "Python"
    case javascript = "JavaScript"
    case typescript = "TypeScript"
    case kotlin     = "Kotlin"
    case java       = "Java"
    case go         = "Go"
    case rust       = "Rust"
    case c          = "C"
    case cpp        = "C++"
    case csharp     = "C#"
    case ruby       = "Ruby"
    case php        = "PHP"
    case sql        = "SQL"
    case html       = "HTML"
    case css        = "CSS"
    case json       = "JSON"
    case yaml       = "YAML"
    case shell      = "Shell"
    case markdown   = "Markdown"

    var id: String { rawValue }

    static func from(_ hint: String) -> CodeLanguage {
        let lowered = hint.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return allCases.first { $0.rawValue.lowercased() == lowered } ?? .plainText
    }
}

// MARK: - Themes

enum CodeTheme: String, CaseIterable, Identifiable {
    case lystaria   = "Lystaria"
    case aura       = "Aura"
    case dracula    = "Dracula"
    case monokai    = "Monokai"
    case githubDark = "GitHub Dark"
    case nord       = "Nord"
    case solarized  = "Solarized"

    var id: String { rawValue }

    static func from(_ hint: String) -> CodeTheme {
        let lowered = hint.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return allCases.first { $0.rawValue.lowercased() == lowered } ?? .lystaria
    }

    var colors: CodeThemeColors {
        switch self {
        case .lystaria:
            return CodeThemeColors(
                background: UIColor(red: 0.08, green: 0.06, blue: 0.14, alpha: 1),
                text:       UIColor(red: 0.92, green: 0.90, blue: 0.98, alpha: 1),
                keyword:    UIColor(red: 0.73, green: 0.52, blue: 0.98, alpha: 1),
                string:     UIColor(red: 0.52, green: 0.90, blue: 0.76, alpha: 1),
                number:     UIColor(red: 0.98, green: 0.72, blue: 0.52, alpha: 1),
                comment:    UIColor(red: 0.55, green: 0.52, blue: 0.65, alpha: 1),
                operator_:  UIColor(red: 0.90, green: 0.60, blue: 0.80, alpha: 1),
                type_:      UIColor(red: 0.60, green: 0.82, blue: 0.98, alpha: 1),
                function_:  UIColor(red: 0.85, green: 0.78, blue: 0.98, alpha: 1)
            )
        case .aura:
            return CodeThemeColors(
                background: UIColor(red: 0.09, green: 0.08, blue: 0.13, alpha: 1),
                text:       UIColor(red: 0.91, green: 0.88, blue: 0.99, alpha: 1),
                keyword:    UIColor(red: 0.67, green: 0.47, blue: 0.98, alpha: 1),
                string:     UIColor(red: 0.61, green: 0.90, blue: 0.69, alpha: 1),
                number:     UIColor(red: 0.98, green: 0.65, blue: 0.44, alpha: 1),
                comment:    UIColor(red: 0.44, green: 0.41, blue: 0.56, alpha: 1),
                operator_:  UIColor(red: 0.94, green: 0.52, blue: 0.75, alpha: 1),
                type_:      UIColor(red: 0.52, green: 0.78, blue: 0.98, alpha: 1),
                function_:  UIColor(red: 0.80, green: 0.63, blue: 0.99, alpha: 1)
            )
        case .dracula:
            return CodeThemeColors(
                background: UIColor(red: 0.16, green: 0.16, blue: 0.21, alpha: 1),
                text:       UIColor(red: 0.97, green: 0.97, blue: 0.95, alpha: 1),
                keyword:    UIColor(red: 0.94, green: 0.46, blue: 0.69, alpha: 1),
                string:     UIColor(red: 0.71, green: 0.93, blue: 0.47, alpha: 1),
                number:     UIColor(red: 0.73, green: 0.60, blue: 0.93, alpha: 1),
                comment:    UIColor(red: 0.38, green: 0.45, blue: 0.55, alpha: 1),
                operator_:  UIColor(red: 0.94, green: 0.46, blue: 0.69, alpha: 1),
                type_:      UIColor(red: 0.55, green: 0.90, blue: 0.94, alpha: 1),
                function_:  UIColor(red: 0.50, green: 0.82, blue: 0.90, alpha: 1)
            )
        case .monokai:
            return CodeThemeColors(
                background: UIColor(red: 0.15, green: 0.15, blue: 0.14, alpha: 1),
                text:       UIColor(red: 0.97, green: 0.97, blue: 0.95, alpha: 1),
                keyword:    UIColor(red: 0.98, green: 0.15, blue: 0.45, alpha: 1),
                string:     UIColor(red: 0.89, green: 0.86, blue: 0.34, alpha: 1),
                number:     UIColor(red: 0.68, green: 0.51, blue: 0.98, alpha: 1),
                comment:    UIColor(red: 0.46, green: 0.46, blue: 0.39, alpha: 1),
                operator_:  UIColor(red: 0.98, green: 0.15, blue: 0.45, alpha: 1),
                type_:      UIColor(red: 0.40, green: 0.85, blue: 0.94, alpha: 1),
                function_:  UIColor(red: 0.65, green: 0.89, blue: 0.18, alpha: 1)
            )
        case .githubDark:
            return CodeThemeColors(
                background: UIColor(red: 0.08, green: 0.10, blue: 0.13, alpha: 1),
                text:       UIColor(red: 0.85, green: 0.89, blue: 0.94, alpha: 1),
                keyword:    UIColor(red: 1.00, green: 0.47, blue: 0.78, alpha: 1),
                string:     UIColor(red: 0.64, green: 0.87, blue: 0.55, alpha: 1),
                number:     UIColor(red: 0.78, green: 0.62, blue: 1.00, alpha: 1),
                comment:    UIColor(red: 0.52, green: 0.60, blue: 0.68, alpha: 1),
                operator_:  UIColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1),
                type_:      UIColor(red: 0.72, green: 0.89, blue: 1.00, alpha: 1),
                function_:  UIColor(red: 0.84, green: 0.74, blue: 1.00, alpha: 1)
            )
        case .nord:
            return CodeThemeColors(
                background: UIColor(red: 0.18, green: 0.20, blue: 0.25, alpha: 1),
                text:       UIColor(red: 0.85, green: 0.87, blue: 0.91, alpha: 1),
                keyword:    UIColor(red: 0.53, green: 0.75, blue: 0.82, alpha: 1),
                string:     UIColor(red: 0.64, green: 0.75, blue: 0.55, alpha: 1),
                number:     UIColor(red: 0.71, green: 0.56, blue: 0.68, alpha: 1),
                comment:    UIColor(red: 0.46, green: 0.52, blue: 0.60, alpha: 1),
                operator_:  UIColor(red: 0.53, green: 0.75, blue: 0.82, alpha: 1),
                type_:      UIColor(red: 0.56, green: 0.74, blue: 0.73, alpha: 1),
                function_:  UIColor(red: 0.50, green: 0.63, blue: 0.75, alpha: 1)
            )
        case .solarized:
            return CodeThemeColors(
                background: UIColor(red: 0.00, green: 0.17, blue: 0.21, alpha: 1),
                text:       UIColor(red: 0.51, green: 0.58, blue: 0.59, alpha: 1),
                keyword:    UIColor(red: 0.52, green: 0.60, blue: 0.00, alpha: 1),
                string:     UIColor(red: 0.52, green: 0.60, blue: 0.00, alpha: 1),
                number:     UIColor(red: 0.82, green: 0.44, blue: 0.19, alpha: 1),
                comment:    UIColor(red: 0.35, green: 0.43, blue: 0.46, alpha: 1),
                operator_:  UIColor(red: 0.40, green: 0.51, blue: 0.51, alpha: 1),
                type_:      UIColor(red: 0.15, green: 0.55, blue: 0.82, alpha: 1),
                function_:  UIColor(red: 0.15, green: 0.55, blue: 0.82, alpha: 1)
            )
        }
    }
}

struct CodeThemeColors {
    let background: UIColor
    let text:       UIColor
    let keyword:    UIColor
    let string:     UIColor
    let number:     UIColor
    let comment:    UIColor
    let operator_:  UIColor
    let type_:      UIColor
    let function_:  UIColor
}

// MARK: - Token Types

enum CodeTokenType {
    case keyword, string, number, comment, operator_, type_, function_, plain
}

struct CodeToken {
    let range: NSRange
    let type: CodeTokenType
}

// MARK: - Highlighter

struct CodeHighlighter {

    static func highlight(_ text: String, language: CodeLanguage, theme: CodeTheme) -> NSAttributedString {
        let colors = theme.colors
        let font = UIFont.monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        let base: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: colors.text,
            .paragraphStyle: paragraphStyle
        ]

        let mutable = NSMutableAttributedString(string: text, attributes: base)
        guard language != .plainText, !text.isEmpty else { return mutable }

        let tokens = tokenize(text, language: language)
        for token in tokens {
            let color: UIColor
            switch token.type {
            case .keyword:   color = colors.keyword
            case .string:    color = colors.string
            case .number:    color = colors.number
            case .comment:   color = colors.comment
            case .operator_: color = colors.operator_
            case .type_:     color = colors.type_
            case .function_: color = colors.function_
            case .plain:     continue
            }
            mutable.addAttribute(.foregroundColor, value: color, range: token.range)
        }
        return mutable
    }

    static func tokenize(_ text: String, language: CodeLanguage) -> [CodeToken] {
        var tokens: [CodeToken] = []
        let nsText = text as NSString
        let length = nsText.length
        var occupied = [Bool](repeating: false, count: length)

        func addToken(_ range: NSRange, _ type: CodeTokenType) {
            guard range.location >= 0, range.location + range.length <= length else { return }
            for i in range.location..<(range.location + range.length) { if occupied[i] { return } }
            for i in range.location..<(range.location + range.length) { occupied[i] = true }
            tokens.append(CodeToken(range: range, type: type))
        }

        func apply(_ pattern: String, type: CodeTokenType, options: NSRegularExpression.Options = []) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
            for match in regex.matches(in: text, range: NSRange(location: 0, length: length)) {
                let range = match.range(at: match.numberOfRanges > 1 ? 1 : 0)
                if range.location != NSNotFound { addToken(range, type) }
            }
        }

        // Comments
        switch language {
        case .python, .ruby, .shell, .yaml: apply(#"#[^\n]*"#, type: .comment)
        case .html: apply(#"<!--[\s\S]*?-->"#, type: .comment)
        case .css: apply(#"/\*[\s\S]*?\*/"#, type: .comment)
        case .sql:
            apply(#"--[^\n]*"#, type: .comment)
            apply(#"/\*[\s\S]*?\*/"#, type: .comment)
        case .json, .markdown, .plainText: break
        default:
            apply(#"//[^\n]*"#, type: .comment)
            apply(#"/\*[\s\S]*?\*/"#, type: .comment)
        }

        // Strings
        switch language {
        case .python:
            apply(#"\"\"\"[\s\S]*?\"\"\""#, type: .string)
            apply(#"'''[\s\S]*?'''"#, type: .string)
            apply(#""(?:[^"\\]|\\.)*""#, type: .string)
            apply(#"'(?:[^'\\]|\\.)*'"#, type: .string)
        case .json:
            apply(#""(?:[^"\\]|\\.)*""#, type: .string)
        default:
            apply(#"`(?:[^`\\]|\\.)*`"#, type: .string)
            apply(#""(?:[^"\\]|\\.)*""#, type: .string)
            apply(#"'(?:[^'\\]|\\.)*'"#, type: .string)
        }

        // Numbers
        apply(#"\b0x[0-9a-fA-F]+\b"#, type: .number)
        apply(#"\b\d+\.?\d*([eE][+-]?\d+)?\b"#, type: .number)

        // Keywords
        let kws = keywords(for: language)
        if !kws.isEmpty {
            apply(#"\b("# + kws.joined(separator: "|") + #")\b"#, type: .keyword)
        }

        // Types
        switch language {
        case .swift, .kotlin, .typescript, .java, .csharp, .rust, .cpp:
            apply(#"\b[A-Z][a-zA-Z0-9_]+\b"#, type: .type_)
        case .html:
            apply(#"</?([a-zA-Z][a-zA-Z0-9]*)"#, type: .type_)
        default: break
        }

        // Functions
        switch language {
        case .swift, .python, .javascript, .typescript, .kotlin, .java, .go, .rust, .c, .cpp, .csharp, .ruby, .php:
            apply(#"\b([a-z_][a-zA-Z0-9_]*)\s*(?=\()"#, type: .function_)
        case .css:
            apply(#"([a-z-]+)\s*(?=\s*:)"#, type: .function_)
        default: break
        }

        // Operators
        switch language {
        case .plainText, .markdown, .yaml, .json: break
        default: apply(#"[+\-*/%=<>!&|^~?:@]+"#, type: .operator_)
        }

        return tokens
    }

    static func keywords(for language: CodeLanguage) -> [String] {
        switch language {
        case .swift:
            return ["actor","any","as","associatedtype","async","await","break","case","catch","class",
                    "continue","default","defer","deinit","do","else","enum","extension","fallthrough",
                    "false","fileprivate","final","for","func","get","guard","if","import","in","init",
                    "inout","internal","is","lazy","let","mutating","nil","nonisolated","nonmutating",
                    "open","operator","override","precedencegroup","private","protocol","public","repeat",
                    "required","rethrows","return","Self","self","set","some","static","struct","subscript",
                    "super","switch","throw","throws","true","try","type","typealias","unowned","var",
                    "weak","where","while","willSet","didSet"]
        case .python:
            return ["and","as","assert","async","await","break","class","continue","def","del","elif",
                    "else","except","False","finally","for","from","global","if","import","in","is",
                    "lambda","None","nonlocal","not","or","pass","raise","return","True","try","while",
                    "with","yield"]
        case .javascript, .typescript:
            return ["abstract","any","as","async","await","boolean","break","case","catch","class",
                    "const","constructor","continue","debugger","declare","default","delete","do","else",
                    "enum","export","extends","false","finally","for","from","function","get","if",
                    "implements","import","in","instanceof","interface","keyof","let","module","namespace",
                    "never","new","null","number","object","of","override","private","protected","public",
                    "readonly","return","require","set","static","string","super","switch","symbol","this",
                    "throw","true","try","type","typeof","undefined","unknown","var","void","while","yield"]
        case .kotlin:
            return ["abstract","actual","annotation","as","break","by","catch","class","companion","const",
                    "constructor","continue","crossinline","data","do","dynamic","else","enum","expect",
                    "external","false","final","finally","for","fun","get","if","import","in","infix","init",
                    "inline","inner","interface","internal","is","it","lateinit","noinline","null","object",
                    "open","operator","out","override","package","private","protected","public","reified",
                    "return","sealed","set","super","suspend","tailrec","this","throw","true","try",
                    "typealias","val","value","var","vararg","when","where","while"]
        case .java:
            return ["abstract","assert","boolean","break","byte","case","catch","char","class","const",
                    "continue","default","do","double","else","enum","extends","final","finally","float",
                    "for","goto","if","implements","import","instanceof","int","interface","long","native",
                    "new","null","package","private","protected","public","return","short","static",
                    "strictfp","super","switch","synchronized","this","throw","throws","transient","true",
                    "false","try","void","volatile","while"]
        case .go:
            return ["break","case","chan","const","continue","default","defer","else","fallthrough","false",
                    "for","func","go","goto","if","import","interface","map","nil","package","range",
                    "return","select","struct","switch","true","type","var"]
        case .rust:
            return ["as","async","await","break","const","continue","crate","dyn","else","enum","extern",
                    "false","fn","for","if","impl","in","let","loop","match","mod","move","mut","pub",
                    "ref","return","self","Self","static","struct","super","trait","true","type","union",
                    "unsafe","use","where","while"]
        case .c, .cpp:
            return ["auto","break","case","char","const","continue","default","do","double","else","enum",
                    "extern","false","float","for","goto","if","inline","int","long","namespace","new",
                    "nullptr","operator","private","protected","public","register","return","short","signed",
                    "sizeof","static","struct","switch","template","this","throw","true","try","typedef",
                    "union","unsigned","using","virtual","void","volatile","while"]
        case .csharp:
            return ["abstract","as","base","bool","break","byte","case","catch","char","checked","class",
                    "const","continue","decimal","default","delegate","do","double","else","enum","event",
                    "explicit","extern","false","finally","fixed","float","for","foreach","goto","if",
                    "implicit","in","int","interface","internal","is","lock","long","namespace","new","null",
                    "object","operator","out","override","params","private","protected","public","readonly",
                    "ref","return","sbyte","sealed","short","sizeof","stackalloc","static","string","struct",
                    "switch","this","throw","true","try","typeof","uint","ulong","unchecked","unsafe",
                    "ushort","using","var","virtual","void","volatile","while"]
        case .ruby:
            return ["alias","and","begin","break","case","class","def","defined","do","else","elsif","end",
                    "ensure","false","for","if","in","module","next","nil","not","or","redo","rescue",
                    "retry","return","self","super","then","true","undef","unless","until","when","while","yield"]
        case .php:
            return ["abstract","and","array","as","break","callable","case","catch","class","clone","const",
                    "continue","declare","default","die","do","echo","else","elseif","empty","enddeclare",
                    "endfor","endforeach","endif","endswitch","endwhile","eval","exit","extends","false",
                    "final","finally","fn","for","foreach","function","global","goto","if","implements",
                    "include","instanceof","insteadof","interface","isset","list","match","namespace","new",
                    "null","or","print","private","protected","public","readonly","require","return","static",
                    "switch","throw","trait","true","try","unset","use","var","while","xor","yield"]
        case .sql:
            return ["ADD","ALL","ALTER","AND","AS","ASC","BETWEEN","BY","CASE","COLUMN","CONSTRAINT",
                    "CREATE","CROSS","DATABASE","DEFAULT","DELETE","DESC","DISTINCT","DROP","ELSE","END",
                    "EXISTS","FOREIGN","FROM","FULL","GROUP","HAVING","IN","INDEX","INNER","INSERT","INTO",
                    "IS","JOIN","KEY","LEFT","LIKE","LIMIT","NOT","NULL","ON","OR","ORDER","OUTER",
                    "PRIMARY","REFERENCES","RIGHT","SELECT","SET","TABLE","THEN","TOP","TRUNCATE","UNION",
                    "UNIQUE","UPDATE","VALUES","VIEW","WHEN","WHERE","WITH"]
        case .html:
            return ["doctype","html","head","body","div","span","p","a","h1","h2","h3","h4","h5","h6",
                    "ul","ol","li","table","tr","td","th","thead","tbody","form","input","button","select",
                    "textarea","label","script","style","link","meta","img","video","audio","canvas","svg",
                    "section","article","header","footer","nav","main","aside","figure","figcaption"]
        case .css:
            return ["important","px","em","rem","vh","vw","auto","none","block","flex","grid","inline",
                    "absolute","relative","fixed","sticky","center","left","right","top","bottom","bold",
                    "normal","solid","dashed","dotted","transparent","inherit","initial","unset"]
        case .shell:
            return ["if","then","else","elif","fi","for","while","do","done","case","esac","function",
                    "return","exit","export","local","readonly","echo","printf","read","source","alias",
                    "unset","cd","pwd","ls","mkdir","rm","cp","mv","grep","sed","awk","cat","chmod","chown"]
        case .markdown, .json, .yaml, .plainText:
            return []
        }
    }
}
