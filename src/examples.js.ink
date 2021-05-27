` example Ink programs repository `

Examples := {
	'Hello World': 'log(\'Hello, \' + \'World!\')'
	'FizzBuzz': 'fizzbuzz := n => each(
	range(1, n + 1, 1)
	n => [n % 3, n % 5] :: {
		[0, 0] -> log(\'FizzBuzz\')
		[0, _] -> log(\'Fizz\')
		[_, 0] -> log(\'Buzz\')
		_ -> log(n)
	}
)

fizzbuzz(20)'
	'Fibonacci': '` naive implementation `
fib := n => n :: {
	0 -> 0
	1 -> 1
	_ -> fib(n - 1) + fib(n - 2)
}

` memoized / dynamic programming implementation `
memo := [0, 1]
fibMemo := n => (
	memo.(n) :: {
		() -> memo.(n) := fibMemo(n - 1) + fibMemo(n - 2)
	}
	memo.(n)
)

out(\'Naive solution: \'), log(fib(20))
out(\'Dynamic solution: \'), log(fibMemo(20))'
	'Prime sieve': '` Ink prime sieve `

` we compute primes up to this limit `
Max := 100

` is a single number prime? `
prime? := n => (
	` is n coprime with nums < p? `
	max := floor(pow(n, 0.5)) + 1
	(ip := p => p :: {
		max -> true
		_ -> n % p :: {
			0 -> false
			_ -> ip(p + 1)
		}
	})(2)
)

` primes under N are numbers 2 .. N, filtered by prime? `
getPrimesUnder := n => filter(range(2, n, 1), prime?)

` display results `
primes := getPrimesUnder(Max)
log(f(\'Total number of primes under {{ 0 }}: {{ 1 }}\'
	[Max, len(primes)]))
log(stringList(primes))'
}
