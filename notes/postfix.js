// Calculate the value of a mathematical expression written in postfix notation
// (reverse polish notation)

// Postfix notation:
// 3 + 4 in postfix notation is 3 4 +
// 3 + 4 * 5 in postfix notation is 3 4 5 * +

class Postfix {

  tokenize(expression) {
    this.tokens = expression.match(/[0-9]+|\+|\-|\*|\//g);
  }

  evaluate() {
    var stack = [];

    this.tokens.forEach((token) => {
      if (token.match(/[0-9]+/)) { // it's a number
        stack.push(token);
      } else if (token.match(/\+|\-|\*|\//)) { // it's an operator
        let leftOperand = stack.pop();
        let rightOperand = stack.pop();
        stack.push(eval(leftOperand + token + rightOperand));
      }
    });

    return stack.pop();
  }

  compute(expression) {
    this.tokenize(expression);
    return this.evaluate();
  }

}

console.log(new Postfix().compute("3 4 +")); // 3 + 4 = 7
console.log(new Postfix().compute("3 4 5 + *")); // (4 + 5) * 3 = 27
