import Foundation

enum Token: Equatable {
    
    case char(Character)
    case alter  // |
    case zeroOrOne  // ?
    case zeroOrMore  // *
    case oneOrMore  // +
    case none
    
    static func map(_ char: Character) -> Token {
        let dict = [
            "*": Token.zeroOrMore,
            "?": Token.zeroOrOne,
            "+": Token.oneOrMore,
            "|": Token.alter
        ]
        return dict[String(char), default: Token.char(char)]
    }
    
}

class State: Equatable, CustomStringConvertible {
    
    static var counter = 0
    
    var id: Int
    var nexts: [State]
    var edge = Character("ε")
    var visited = false
    
    init() {
        id = State.counter
        State.counter += 1
        
        nexts = [State]()
    }
    
    static func == (lhs: State, rhs: State) -> Bool {
        return lhs.id == rhs.id
    }
    
    var description: String {
        return "id: \(id), edge: \(edge)"
    }
    
}

/// 两个节点作为一个转移
class StateTransition {
    
    var startNode: State?
    var endNode: State?
    
}

class Lexer {
    
    private var pattern: [Character]
    private var pos = 0
    
    var currentToken = Token.none
    var lexeme = Character("ε")
    
    init(_ pattern: String) {
        self.pattern = Array(pattern)
    }
    
    func advance() -> Token {
        guard pos < pattern.count else {
            currentToken = .none
            return .none
        }
        
        currentToken = Token.map(pattern[pos])
        lexeme = pattern[pos]
            
        pos += 1
        
        return currentToken
    }
    
    func match(_ token: Token) -> Bool {
        return currentToken == token
    }
    
}

class Parser {
    
    /*
     expr   ::= conn ("|" conn)*
     conn   ::= factor | factor*
     factor ::= (term | term ("*" | "+" | "?"))*
     term   ::= char
     */
    
    static var lexer: Lexer!
    
    static func parse(_ pattern: String) -> State {
        lexer = Lexer(pattern)
        _ = lexer.advance()
        var trans = StateTransition()
        _ = regexToState(&trans)
        return trans.startNode!
    }
    
    static func regexToState(_ trans: inout StateTransition) -> Bool {
        _ = expr(&trans)
        return true
    }
    
    static func expr(_ trans: inout StateTransition) -> Bool {
        _ = conn(&trans)
        
        var newTrans = StateTransition()
        while lexer.match(.alter) {
            _ = lexer.advance()
            _ = conn(&newTrans)
            
            let start = State()
            start.nexts.append(newTrans.startNode!)
            start.nexts.append(trans.startNode!)
            trans.startNode = start
            
            let end = State()
            newTrans.endNode?.nexts.append(end)
            trans.endNode?.nexts.append(end)
            trans.endNode = end
        }
        
        return true
    }
    
    static func conn(_ trans: inout StateTransition) -> Bool {
        if isConn(lexer.currentToken) {
            _ = factor(&trans)
        }
        
        while isConn(lexer.currentToken) {
            var newTrans = StateTransition()
            _ = factor(&newTrans)
            trans.endNode?.nexts.append(newTrans.startNode!)
            trans.endNode = newTrans.endNode
        }
        
        return true
    }
    
    static func factor(_ trans: inout StateTransition) -> Bool {
        _ = term(&trans)
        if lexer.match(.zeroOrMore) {
            _ = zeroOrMore(&trans)
        } else if lexer.match(.zeroOrOne) {
            _ = zeroOrOne(&trans)
        } else if lexer.match(.oneOrMore) {
            _ = oneOrMore(&trans)
        }
        
        return true
    }
    
    /// 处理字符
    /// - Parameter trans: 新的转移
    static func term(_ trans: inout StateTransition) -> Bool {
        let start = State()
        trans.startNode = start
        
        let end = State()
        trans.startNode?.nexts.append(end)
        trans.endNode = end
        
        start.edge = lexer.lexeme
        
        _ = lexer.advance()
        
        return true
    }
    
    static func zeroOrMore(_ trans: inout StateTransition) -> Bool {
        if !lexer.match(.zeroOrMore) {
            return false
        }
        
        // 新增起始和结束状态
        let start = State()
        let end = State()
        
        // 新的起始状态指向原来的起始状态
        // 并且新的起始状态能直接转移到新的结束状态
        start.nexts.append(trans.startNode!)
        start.nexts.append(end)
        
        // 原来的结束状态现在可以转移到自身的开始状态
        // 并且能转移到新的结束状态
        trans.endNode?.nexts.append(trans.startNode!)
        trans.endNode?.nexts.append(end)
        
        // 整个转移有了新的起始和结束状态
        trans.startNode = start
        trans.endNode = end
        
        _ = lexer.advance()
        
        return true
    }
    
    static func zeroOrOne(_ trans: inout StateTransition) -> Bool {
        if !lexer.match(.zeroOrOne) {
            return false
        }
        
        let start = State()
        let end = State()
        
        start.nexts.append(trans.startNode!)
        start.nexts.append(end)
        
        trans.startNode = start
        trans.endNode = end
        trans.endNode?.nexts.append(end)
        
        _ = lexer.advance()
        
        return true
    }
    
    static func oneOrMore(_ trans: inout StateTransition) -> Bool {
        if !lexer.match(.oneOrMore) {
            return false
        }
        
        let start = State()
        let end = State()
        
        start.nexts.append(trans.startNode!)
        
        trans.startNode = start
        trans.endNode = end
        trans.endNode?.nexts.append(trans.startNode!)
        trans.endNode?.nexts.append(end)
        
        _ = lexer.advance()
        
        return true

    }
    
    static func isConn(_ token: Token) -> Bool {
        switch token {
        case .alter: fallthrough
        case .zeroOrOne: fallthrough
        case .oneOrMore: fallthrough
        case .zeroOrMore: fallthrough
        case .none:
            return false
        default:
            return true
        }
    }
    
}

class Regex {
    
    var startState: State
    
    init(_ pattern: String) {
        self.startState = Parser.parse(pattern)
    }
    
    func isMatch(_ input: String) -> Bool {
        return match(input, self.startState)
    }
    
    private func match(_ input: String,  _ state: State) -> Bool {
        var currentStateSet = [state]
        var nextStateSet = closure(currentStateSet)
        
        for (i, c) in input.enumerated() {
            currentStateSet = move(nextStateSet, c)
            nextStateSet = closure(currentStateSet)
            
            if nextStateSet.isEmpty {
                return false
            }
            
            if isAcceptable(nextStateSet) && i == input.count - 1 {
                return true
            }
        }
        
        return false
    }
    
    /// 计算当前状态集的 ε 闭包
    private func closure(_ set: [State]) -> [State] {
        var res = set
        var stack = [State]()
        for state in set {
            stack.append(state)
        }
        
        while stack.count > 0 {
            let state = stack.removeLast()
            if state.edge == Character("ε") {
                for next in state.nexts {
                    res.append(next)
                    stack.append(next)
                }
            }
        }
        
        return res
    }
    
    /// 计算当前状态集在输入一个字符时得到的下一个状态集
    private func move(_ set: [State], _ c: Character) -> [State] {
        var res = [State]()
        for state in set where state.edge == c {
            for next in state.nexts {
                res.append(next)
            }
        }
        return res
    }
    
    private func isAcceptable(_ set: [State]) -> Bool {
        for state in set where state.nexts.isEmpty {
            return true
        }
        return false
    }
    
}

let regex = Regex("ab*c")
regex.isMatch("abbc")
