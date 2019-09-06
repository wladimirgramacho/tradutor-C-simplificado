# tradutor-C-simplificado
Trabalho de Tradutores @ Universidade de Brasília

### Analisador Léxico
Para executar o analisador léxico, basta executar:

`make flex`

Caso queira ver a tabela de símbolos ao final da análise, adicione a opção `-t` às linhas no arquivo makefile que fazem a execução do programa. Por exemplo:

`./src/lex/lexer examples/valid1.code -t`