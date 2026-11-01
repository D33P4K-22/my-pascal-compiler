# Mini-Pascal Compiler

A 4-stage compiler pipeline and execution runtime engine for Mini-Pascal built using C, Flex, and Bison.

## Project Structure

- **Lexical-Analysis/**: Tokenizes source files into identifiers, keywords, literals, and operators.
- **Syntax-Analysis/**: Validates context-free grammar rules using Bison parser tables.
- **Semantic-Analysis/**: Builds Abstract Syntax Trees (AST) and enforces variable scope & type checking.
- **Final-Stage/**: Executes AST nodes in-memory and outputs the final Symbol Table.

## Key Features

- **Language Support:** `integer`, `real`, `boolean`, `char`, and 1D static arrays.
- **Control Flow:** `if-then-else`, `while-do`, `for-to-do`, and `for-downto-do`.
- **Semantic Guardrails:** Catches undeclared variables, duplicate declarations, and type mismatch assignments.

## Sample Output

```text
Input:  for i := 1 to 5 do sum := sum + i;

Symbol Table Output:
Variable    | Type      | Value
i           | integer   | 6
sum         | integer   | 15
