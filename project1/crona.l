%{
#include <string>
#include <limits.h>

/* Get our custom yyFlexScanner subclass */
#include "scanner.hpp"
#include "tokens.hpp"
using namespace std;
#undef  YY_DECL
#define YY_DECL int crona::Scanner::yylex( crona::Parser::semantic_type * const lval )

/* define yyterminate as this instead of NULL */
#define yyterminate() return( TokenKind::END )

/* Exclude unistd.h for Visual Studio compatability. */
#define YY_NO_UNISTD_H

/* typedef to make the reference to token kinds shorter */
using TokenKind = crona::Parser::token;

%}

%option debug
%option nodefault
%option yyclass="crona::Scanner"
%option noyywrap
%option c++

DIGIT [0-9]
IDALPHA [0-9A-Z_a-z]
STRING [ !#-[]-~]

%%
%{          /** Code executed at the beginning of yylex **/
            yylval = lval;
%}

"+"		{
		// Keep track of the "kind" of token we matched. In this case,
		// it's a CROSS (aka the plus symbol). The full list of token
		// kinds is declared around line 197 of grammar.hh. The testing
		// functionScanner::outputTokens also indicates what each token
		// represents (declared in scanner.cpp line 9)
		int tokenKind = TokenKind::CROSS;

		//Instatiate a token. There are 4 classes of tokens defined based on
		// - a literal string (StringLitToken)
		// - a literal integer (IntLitToken)
		// - an identifier (IDToken)
		// - a base Token (any other type)
		// The token object is a handy place to keep information about the
		// token (i.e. token metadata) such as the line and column on which
		// the token character started (which can be used later in debug
		// messages, etc).
		Token * token = new Token(lineNum, colNum, tokenKind);

		//Assign the token to a instance variable of the scanner.
		// (When Flex processes a .l file in C++ mode, it creates
		// a class called Scanner, which is a subclass of yyFlexScanner)
		// By assigning a value to this field, we put the token
		// metadata in a place where scanner's client program can find it.
		this->yylval->lexeme = token;

		//Since we consumed 1 character, increase the column number by 1
		colNum++;

		//Let the scanner's client program know that a CROSS token
		// has been matched
		return tokenKind;
		}

"-" {
		//Essentially the same thing as CROSS, but without the verbose
		// comments so it doesn't look so scary.
		int tokenKind = TokenKind::DASH;
		this->yylval->lexeme = new Token(lineNum, colNum, tokenKind);
		colNum++;
		return tokenKind;
		}

\\q  {
    std::string msg = "FATAL [" + to_string(lineNum) + "," + to_string(colNum) + "]: String literal with bad escape seqeunce ignored ";
    msg += yytext;
    error(lineNum,colNum,msg);
    colNum += yyleng;
    }

\\n  {
    std::string msg = "FATAL [" + to_string(lineNum) + "," + to_string(colNum) + "]: Unterminated string literal ignored ";
    msg += yytext;
    error(lineNum,colNum,msg);
    colNum += yyleng;
    }

\\eof  {
    std::string msg = "FATAL [" + to_string(lineNum) + "," + to_string(colNum) + "]: Unterminated string literal ignored ";
    msg += yytext;
    error(lineNum,colNum,msg);
    colNum += yyleng;
    }

{DIGIT}+	{
		//TODO: The following computation of the integer
		// value does not check for overflow. It should do so.
		int intVal = atoi(yytext);


		//Note that the IntLitToken does not take a TokenKind argument
		// since it's implicitly known that the token represents an
		// INTLITERAL

      if (stod(yytext) >= 2147483648.000) {
        std::string msg = "WARN [" + to_string(lineNum) + "," + to_string(colNum) + "]: Integer literal too large; using max value ";
        msg += yytext;
        error(lineNum,colNum,msg);
      }

    yylval->lexeme = new IntLitToken(lineNum, colNum, intVal);

    //TODO: update the colNum count according to the number of
    // characters consumed.

    //As before, alert the client program that an INTLITERAL
    // token was matched
    return TokenKind::INTLITERAL;
		}

{IDALPHA}+   {
    string idVal = yytext;
    yylval->lexeme = new IDToken(lineNum, colNum, idVal);
    colNum += yyleng;

    return TokenKind::ID;
    }

"{STRING}*" {
    string stringVal = yytext;
    yylval->lexeme = new StrToken(lineNum, colNum, stringVal);
    colNum += yyleng;

    return TokenKind::STRLITERAL;
    }

"{STRING}*\\{STRING}*"  {
    std::string msg = "FATAL [" + to_string(lineNum) + "," + to_string(colNum) + "]: Unterminated string literal with bad escaped character ignored ";
    msg += yytext;
    error(lineNum,colNum,msg);
    colNum += yyleng;
    }

\n		{
		//Update the line number, reset the columnNumber
		lineNum++;
		colNum = 0;
		}

" " { }

.   {
		//TODO: Add the rest of the rules above this point so that legal characters
		// are properly accounted for.
		std::string msg = "FATAL [" + to_string(lineNum) + "," + to_string(colNum) + "]: Illegal character ";
		msg += yytext;
		error(lineNum,colNum,msg);
		colNum += yyleng;
    }
%%
