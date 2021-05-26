` Main application UI `

Tab := char(9)
Newline := char(10)

` utility fns `

getItem := bind(localStorage, 'getItem')
setItem := bind(localStorage, 'setItem')
removeItem := bind(localStorage, 'removeItem')

` a debounce with leading edge, 1 hard-coded argument `
delay := (fn, timeout) => (
	S := {
		to: ()
	}
	dateNow := bind(Date, 'now')

	arg => (
		clearTimeout(S.to)
		S.to := setTimeout(() => fn(arg), timeout)
	)
)

` September interface `

` from translate.ink > main: the load() here has no runtime meaning, just
documentational reference to the source file. `
translateInkToJS := load('september/ink/translate').main

` takes a program and synchronously returns the evaluation result as a string `
getEvalOutput := prog => (
	compiled := translateInkToJS(prog)
	` semi-reliable error handling based on September behavior `
	index(compiled, 'err @') :: {
		~1 -> (
			out := s => (
				append(State.replOutputs, split(s, Newline))
				render()
			)
			log := s => out(string(s) + Newline)

			` eval() only works with proper strings `
			replOutput := eval(bind(compiled, 'toString')())
			string(replOutput)
		)
			` TODO: find a better way to propagate error messages `
		_ -> compiled
	}
		)

` components `

Link := (name, href) => ha('a', [], {
	href: href
	target: '_blank'
}, name)

Header := () => h('header', [], [
	'Ink playground'
])

Editor := () => h('editor', [], [
	hae('textarea', [], {value: State.file}, {
		input: evt => (
		  State.file := evt.target.value
		  persistFile()
		  render()
	  )
		keydown: evt => [evt.ctrlKey | evt.metaKey, evt.key] :: {
			[true, 'Enter'] -> runRepl()
			[_, 'Tab'] -> (
				`` TODO: ENTER TAB
			)
		}
	}, [])
])

` TODO: for now, just display output `
Repl := () => h('div', ['repl'], [
	hae('button', [], {}, {
		click: runRepl
	}, ['Run'])
	h('ol', ['replOutput'], map(State.replOutputs, output => h('li', [], [
		h('code', [], [output])
	])))
	hae('input', ['replLine'], {value: State.line}, {
		input: evt => render(State.line := evt.target.value)
		keydown: evt => evt.key :: {
			'Enter' ->  (
				State.replOutputs.len(State.replOutputs) := getEvalOutput(State.line)
				render(State.line := '')
			)
		}
	}, [])
])

` main render loop `

root := bind(document, 'querySelector')('#root')
r := Renderer(root)
update := r.update

State := {
	` editor content `
		file: restored := getItem('State.file') :: {
			() -> '\'Hello, \' + \'World!\''
			_ -> restored
		}
	line: ''
	replOutputs: []
}

` state fns `

clearRepl := () => render(State.replOutputs := [])

` TODO: temporary eval() `
` TODO: reroute I/O from Ink programs through to UI `
runRepl := () => render(State.replOutputs := [getEvalOutput(State.file)])

persistFileImmediately := () => setItem('State.file', State.file)
persistFile := delay(persistFileImmediately, 800)

render := () => (
	` TODO: provide ways to introspect AST? since tkString and ndString are
	already available here `
	update(h('div', ['app'], [
		Header()
		Editor()
		Repl()
	]))
)

render()

