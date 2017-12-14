//
//  SymbolTableBuilder.swift
//  SwiftPascalInterpreter
//
//  Created by Igor Kulman on 10/12/2017.
//  Copyright © 2017 Igor Kulman. All rights reserved.
//

import Foundation

public class SemanticAnalyzer: Visitor {
    private var currentScope: ScopedSymbolTable?
    private var scopes: [String: ScopedSymbolTable] = [:]

    public init() {

    }

    public func analyze(node: AST) -> [String: ScopedSymbolTable] {
        visit(node: node)
        return scopes
    }

    func visit(program: Program) {
        let globalScope = ScopedSymbolTable(name: "global", level: 1, enclosingScope: nil)
        scopes[globalScope.name] = globalScope
        currentScope = globalScope
        visit(node: program.block)
        currentScope = nil
    }

    func visit(variable: Variable) {
        guard let scope = currentScope else {
            fatalError("Cannot access a variable outside a scope")
        }
        guard scope.lookup(variable.name) != nil else {
            fatalError("Symbol(indetifier) not found '\(variable.name)'")
        }
    }

    func visit(variableDeclaration: VariableDeclaration) {
        guard let scope = currentScope else {
            fatalError("Cannot declare a variable outside a scope")
        }

        guard scope.lookup(variableDeclaration.variable.name, currentScopeOnly: true) == nil else {
            fatalError("Duplicate identifier '\(variableDeclaration.variable.name)' found")
        }

        guard let symbolType = scope.lookup(variableDeclaration.type.type.description) else {
            fatalError("Type not found '\(variableDeclaration.type.type.description)'")
        }

        scope.insert(VariableSymbol(name: variableDeclaration.variable.name, type: symbolType))
    }

    func visit(procedure: Procedure) {
        let scope = ScopedSymbolTable(name: procedure.name, level: (currentScope?.level ?? 0) + 1, enclosingScope: currentScope)
        scopes[scope.name] = scope
        currentScope = scope

        var parameters: [Symbol] = []
        for param in procedure.params {
            guard let symbol = scope.lookup(param.type.type.description) else {
                fatalError("Type not found '\(param.type.type.description)'")
            }
            let variable = VariableSymbol(name: param.name, type: symbol)
            parameters.append(variable)
            scope.insert(variable)
        }
        let proc = ProcedureSymbol(name: procedure.name, parameters: parameters, body: procedure)
        scope.enclosingScope?.insert(proc)

        visit(node: procedure.block)
        currentScope = currentScope?.enclosingScope
    }

    func visit(call: ProcedureCall) {
        guard let symbol = currentScope?.lookup(call.name), let procedure = symbol as? ProcedureSymbol else {
            fatalError("Symbol(procedure) not found '\(call.name)'")
        }

        guard procedure.params.count == call.actualParameters.count else {
            fatalError("Procedure called with wrong number of parameters '\(call.name)'")
        }

        guard procedure.params.count > 0 else {
            return
        }

        for i in 0 ... procedure.params.count - 1 {
            guard let variableSymbol = procedure.params[i] as? VariableSymbol, let type = variableSymbol.type as? BuiltInTypeSymbol else {
                fatalError("Procedure declared with wrong parameters '\(call.name)'")
            }

            switch type {
            case .integer:
                switch call.actualParameters[i] {
                case .integer:
                    break
                case .real:
                    fatalError("Cannot assing Real to Integer parameter in procedure call '\(call.name)'")
                }
            case .real:
                break
            }
        }
    }
}