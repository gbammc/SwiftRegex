import Foundation

/**
* 能够表达EBNF的对象。
* 1.每个GrammarNode可以有多个子节点；
* 2.子节点之间可以是And关系，或Or关系，由type属性来确定。
* 3.minTimes和maxTimes属性规定了该节点的重复次数。比如对于+号，minTimes=1，maxTimes=-1，-1代表很多个。
* 4.该节点可以有名称，也就是词法规则和语法规则中左边的部分。如果没有起名称，系统会根据它的父节点的名称生成自己的缺省名称，
* 并且以下划线开头。比如_add_Or_1。
*/
class RegexNode {
    
    enum RegexNodeType {
        case add, or, char, token, epsilon
    }
    
    private var children = [RegexNode]()
    
    private var type: RegexNodeType?
    
    private var charSet: CharSet?
    
    private var minTimes = 1
    private var maxTimes = 1
    
//    private
    
}

