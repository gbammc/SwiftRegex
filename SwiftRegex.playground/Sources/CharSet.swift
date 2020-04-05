import Foundation

/**
* 字符的集合。
* 用于在词法分析时，定义满足条件的字符。它有这几种使用方式：
* 1.代表一个字符
* 2.用起止字符定义一个集合
* 3.对集合取补集
* 4.通过包含多个子集合来定义该集合
*/
public class CharSet: Equatable, CustomStringConvertible {
    
    static let digit = CharSet(from: "0", to: "9")
    static let smallLetter = CharSet(from: "a", to: "z")
    static let capitalLetter = CharSet(from: "A", to: "Z")
    static let letter = initLetter()
    static let letterOrDigit = initLetterOrDigit()
    static let whiteSpace = initWhiteSpace()
    
    static let ascii: [Character] = {
        var alphabet = [Character]()
        for i in 0 ..< 128 {
            let u = UnicodeScalar(i)!
            alphabet.append(Character(u))
        }
        return alphabet
    }()
    static let alphabet = ascii
    static let lettersAndDigits: [Character] = {
        var alphabet = [Character]()
        for i in Character("0").asciiValue! ... Character("9").asciiValue! {
            let u = UnicodeScalar(i)
            alphabet.append(Character(u))
        }
        for i in Character("A").asciiValue! ... Character("Z").asciiValue! {
            let u = UnicodeScalar(i)
            alphabet.append(Character(u))
        }
        for i in Character("a").asciiValue! ... Character("z").asciiValue! {
            let u = UnicodeScalar(i)
            alphabet.append(Character(u))
        }
        return alphabet
    }()
    
    //起始字符
    var from: Character?
    
    //终止字符
    var to: Character?
    
    //是否是取补集，比如[^a]
    var exclude = false
    
    var subSets: [CharSet]?
    
    init() {
        
    }
    
    convenience init(from: Character) {
        self.init(from: from, to: from, exclude: false)
    }
    
    convenience init(from: Character, to: Character) {
        self.init(from: from, to: to, exclude: false)
    }
    
     init(from: Character, to: Character, exclude: Bool) {
        self.from = from
        self.to = to
        self.exclude = exclude
    }
    
    func addSubSet(_ charSet: CharSet) {
        if subSets == nil {
            subSets = [CharSet]()
        }
        subSets?.append(charSet)
    }
    
    func match(_ ch: Character) -> Bool {
        var ret = false
        if let subSets = subSets {
            for subSet in subSets {
                ret = subSet.match(ch)
                if ret {
                    break
                }
            }
        } else if let from = from, let to = to {
            ret = from.asciiValue! <= ch.asciiValue! && ch.asciiValue! <= to.asciiValue!
        }
        if exclude {
            ret = !ret
        }
        return ret
    }
    
    func isEmpty() -> Bool {
        if let subSets = subSets {
            var empty = true
            for charSet in subSets where !charSet.isEmpty() {
                empty = false
                break
            }
            return empty
        } else {
            return from == nil
        }
    }
    
    func shorterForm() -> CharSet {
        if self == CharSet.digit {
            return CharSet.digit
        } else if self == CharSet.smallLetter {
            return CharSet.smallLetter
        } else if self == CharSet.capitalLetter {
            return CharSet.capitalLetter
        } else if self == CharSet.letter {
            return CharSet.letter
        } else if self == CharSet.letterOrDigit {
            return CharSet.letterOrDigit
        } else {
            let charSet = supllementarySet()
            charSet.exclude = true
            return charSet
        }
    }
    
    private static func initLetterOrDigit() -> CharSet {
        let charSet = CharSet()
        charSet.addSubSet(digit)
        charSet.addSubSet(smallLetter)
        charSet.addSubSet(capitalLetter)
        return charSet
    }
    
    private static func initLetter() -> CharSet {
        let charSet = CharSet()
        charSet.addSubSet(smallLetter)
        charSet.addSubSet(capitalLetter)
        return charSet
    }
    
    private static func initWhiteSpace() -> CharSet {
        let charSet = CharSet()
        charSet.addSubSet(CharSet(from: " "))
        charSet.addSubSet(CharSet(from: "\t"))
        charSet.addSubSet(CharSet(from: "\n"))
        return charSet
    }
    
    private func supllementarySet() -> CharSet {
        var charSet = CharSet()
        for ch in CharSet.lettersAndDigits where !match(ch) {
            charSet.addSubSet(CharSet(from: ch))
        }
        if charSet.subSets?.count == 0 {
            charSet = CharSet.letterOrDigit
        }
        return charSet
    }
    
    public var description: String {
        if let subSets = self.subSets {
            var desc = ""
            if exclude {
                desc += "^"
                if subSets.count > 1 {
                    desc += "("
                }
            }
            
            for (i, subset) in subSets.enumerated() {
                if i > 0 {
                    desc += "|"
                }
                desc += subset.description
            }
            
            if exclude && subSets.count > 1 {
                desc += ")"
            }
            
            return desc
        } else if from == to {
            return "\(from ?? Character(""))"
        } else {
            if exclude {
                return "[^\(from ?? Character(""))-\(to ?? Character(""))]"
            } else {
                return "[\(from ?? Character(""))-\(to ?? Character(""))]"
            }
        }
    }
    
    public static func == (lhs: CharSet, rhs: CharSet) -> Bool {
        
        return true
    }
    
}
