require "./lexer"
require "./ast/node"

# Simple calculator grammar for now
#
# ```
# program    = stmt*
# stmt       = expr ";"
# expr       = assign
# assign     = equality ("=" assign)?
# equality   = relational ("==" relational | "!=" relational)*
# relational = add ("<" add | "<=" add | ">" add | ">=" add)*
# add        = mul ("+" mul | "-" mul)*
# mul        = unary ("*" unary | "/" unary)*
# unary      = ("+" | "-")? primary
# primary    = num | ident | "(" expr ")"
# ```
module Z
  class Parser
    class Error < Exception
    end

    alias T = Token::Type
    @tokens : Array(Token)

    def initialize(@code : String)
      @lex = Lexer.new(@code)
      @tokens = [] of Token
      @pos = 0
    end

    def parse
      @tokens = @lex.tokens
      _root
    end

    ##

    private def _root
      return Ast::Nop.new if eof?
      _program
    end

    private def _program
      stmts = [] of Ast::Node
      until eof?
        stmts << _stmt
      end
      Ast::Program.new(stmts)
    end

    private def _stmt
      n = _expr
      consume T::SEMI
      n
    end

    private def _expr
      _assign
    end

    private def _assign
      n = _equality

      if accept T::ASSIGN
        if n.is_a?(Ast::Ident)
          n = Ast::Lvar.new(n.value, n.offset)
          return Ast::Assignment.new(n, _assign)
        else
          error "expected left variable, got `#{curr.value}`"
        end
      end
      n
    end

    private def _equality
      n = _relational

      loop do
        if accept T::EQ
          n = Ast::BinOp.new(:==, n, _relational)
        elsif accept T::NE
          n = Ast::BinOp.new(:!=, n, _relational)
        else
          return n
        end
      end
    end

    private def _relational
      n = _add

      loop do
        if accept T::LT
          n = Ast::BinOp.new(:<, n, _add)
        elsif accept T::LE
          n = Ast::BinOp.new(:<=, n, _add)
        elsif accept T::GE
          n = Ast::BinOp.new(:>=, n, _add)
        elsif accept T::GT
          n = Ast::BinOp.new(:>, n, _add)
        else
          return n
        end
      end
    end

    private def _add
      n = _mul

      loop do
        if accept T::PLUS
          n = Ast::BinOp.new(:+, n, _mul)
        elsif accept T::MIN
          n = Ast::BinOp.new(:-, n, _mul)
        else
          return n
        end
      end
    end

    private def _mul
      n = _unary

      loop do
        if accept T::MUL
          n = Ast::BinOp.new(:*, n, _unary)
        elsif accept T::DIV
          n = Ast::BinOp.new(:/, n, _unary)
        else
          return n
        end
      end
    end

    private def _unary
      if accept T::PLUS
        return _primary
      elsif accept T::MIN
        return Ast::BinOp.new(:-, Ast::NumberLiteral.new("0"), _primary)
      end

      _primary
    end

    private def _primary
      if accept T::LEFT_PAREN
        e = _expr
        consume T::RIGHT_PAREN
        return e
      elsif accept T::INT
        return Ast::NumberLiteral.new(prev.value)
      elsif accept T::IDENT
        offset = (prev.value[0] - 'a' + 1) * 8
        return Ast::Ident.new(prev.value, offset)
      end
      error "expected a parenthesized list, an ident, or a number, got `#{curr.value}`"
    end

    ##

    private def consume(type : T, msg : String? = "")
      unless accept type
        error "expected a #{type}, got `#{curr.value}`"
      end
    end

    private def accept(type)
      if match? type
        @pos += 1
        prev
      end
    end

    private def match?(type)
      return false if eof?
      curr.type == type
    end

    private def eof?
      @pos >= @tokens.size
    end

    private def last?
      @pos == @tokens.size - 1
    end

    private def curr
      error "no tokens available for #curr" if @tokens.size.zero?
      return prev if eof?
      @tokens[@pos]
    end

    private def prev
      error "no tokens available for #prev" if @tokens.empty?
      @tokens[@pos - 1]
    end

    private def error(msg : String)
      raise Error.new(msg)
    end
  end
end