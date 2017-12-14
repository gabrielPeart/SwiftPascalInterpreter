//
//  SymbolTable.swift
//  SwiftPascalInterpreter
//
//  Created by Igor Kulman on 10/12/2017.
//  Copyright © 2017 Igor Kulman. All rights reserved.
//

import Foundation

public class ScopedSymbolTable {
    private var symbols: [String: Symbol] = [:]

    let name: String
    let level: Int
    let enclosingScope: ScopedSymbolTable?

    init(name: String, level: Int, enclosingScope: ScopedSymbolTable?) {
        self.name = name
        self.level = level
        self.enclosingScope = enclosingScope

        insert(BuiltInTypeSymbol.integer)
        insert(BuiltInTypeSymbol.real)
    }

    func insert(_ symbol: Symbol) {
        symbols[symbol.name] = symbol
    }

    func lookup(_ name: String, currentScopeOnly: Bool = false) -> Symbol? {
        if let symbol = symbols[name] {
            return symbol
        }

        if currentScopeOnly {
            return nil
        }

        return enclosingScope?.lookup(name)
    }
}

extension ScopedSymbolTable: CustomStringConvertible {
    public var description: String {
        var lines = ["SCOPE (SCOPED SYMBOL TABLE)", "==========================="]
        lines.append("Scope name    : \(name)")
        lines.append("Scope level   : \(level)")
        lines.append("Scope (Scoped symbol table) contents")
        lines.append("------------------------------------")
        lines.append(contentsOf: symbols.sorted(by: {$0.value.sortOrder < $1.value.sortOrder}).map({ key, value in
            return "\(key.padding(toLength: 7, withPad: " ", startingAt: 0)): \(value)"
        }))
        return lines.reduce("", { $0 + "\n" + $1 })
    }
}