# Mini-Pascal Compiler

A 4-stage compiler pipeline for Mini-Pascal built using C, Flex, and Bison.

## Project Structure

- **Lexical-Analysis/**: Tokenizes source files into identifiers, keywords, literals, and operators.
- **Syntax-Analysis/**: Validates context-free grammar rules using Bison.
- **Semantic-Analysis/**: Builds Abstract Syntax Trees (AST) and validates scope & variable types.
- **Final-Stage/**: Executes AST nodes in-memory and outputs the final Symbol Table.

## Build & Run

Run the build commands inside any stage folder:

```bash
bison -y -d parser.y
flex lexer.l
gcc y.tab.c lex.yy.c -o executable
