#ifndef HOLYCC_TOKEN_HPP
#define HOLYCC_TOKEN_HPP

#include <sstream>
#include <string>
#include <utility>

namespace holycc {

class Token {
public:
  enum class Type {
    PLUS,     // +
    MINUS,    // -
    NUMBER,   // 123
    NEWLINE,  // \n
    END 			// EOF
  };

  const Type type;          // The type of this token
  const std::string lexeme; // The characters that form this token
  const int line,           // The line number of this token
            start,          // The column number of the start of this token
            end;            // The column number of the end of this token

  // @param  type   The token's type
  // @param  lexeme The text of this token
  // @param  line   The line where this token was found
  // @param  start  The starting index of this token
  // @param  end    The ending index of this token
  // @return        A new Token instance
  explicit Token(const Type type, std::string lexeme,
                 const int line, const int start, const int end)
    : type(type), lexeme(std::move(std::move(lexeme))), line(line), start(start), end(end) { }

  // Allows a token instance to be printed using <<
  //
  // @param  output The output stream to write to
  // @param  t      The token instance to write out
  friend std::ostream &operator<<(std::ostream &output, const Token &t) {
    output << t.to_s();
    return output;
  }

  // @return  indention  The amount to indent
  // @return             A string representation of this token
  const std::string to_s(const int indention = 0) const {
    std::ostringstream out;
    std::string indent(indention, ' ');

    out << indent << "Token: [\n"
        << indent << "  type:   [" << static_cast<int>(type) << "]\n"
        << indent << "  line:   [" << line      << "]\n"
        << indent << "  start:  [" << start     << "]\n"
        << indent << "  end:    [" << end       << "]\n"
        << indent << "  lexeme: [" << lexeme    << "]\n"
        << indent << "] // Token";

    return out.str();
  }

  // @param  other  A token instance to compare to this instance
  // @return        Whether this token is the same, member-wise, as other
  bool operator==(const Token &other) {
    return type   == other.type   &&
           lexeme == other.lexeme &&
           line   == other.line   &&
           start  == other.start  &&
           end    == other.end;
  }

  // @param  t1  A token to compare against t2
  // @param  t2  A token to compare against t1
  // @return     Whether the tokens are the same, member-wise
  friend bool operator==(const Token &t1, const Token &t2) {
    return t1.type   == t2.type   &&
           t1.lexeme == t2.lexeme &&
           t1.line   == t2.line   &&
           t1.start  == t2.start  &&
           t1.end    == t2.end;
  }
};

} // namespace holycc
#endif // HOLYCC_TOKEN_HPP