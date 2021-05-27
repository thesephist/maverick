` Main application UI `

Tab := char(9)
Newline := char(10)

Line := {
	Prog: 0
	Result: 1
	Log: 2
	Error: 3
}

Embedded? := ~(window.frameElement = ())

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
evaluateInk := prog => (
	compiled := translateInkToJS(prog)
	` semi-reliable error handling based on September behavior `
	index(compiled, 'parse err @') :: {
		~1 -> (
			out := s => (
				State.replLines.len(State.replLines) := {
					type: Line.Log
					text: s
				}
				render()
				()
			)
			log := s => out(string(s) + Newline)

			` eval() only works with proper strings `
			replOutput := string(eval(str(compiled)))
			State.replLines.len(State.replLines) := {
				type: Line.Result
				text: replOutput
			}
			replOutput
		)
		_ -> State.replLines.len(State.replLines) := {
			type: Line.Error
			text: compiled
		}
	}
)

` components `

Link := (name, href) => ha('a', [], {
	href: href
	target: '_blank'
}, name)

RunButton := () => hae('button', ['runButton'], {title: 'Run code (Ctrl + Enter)'}, {
	click: runRepl
}, ['Run'])

Header := () => h('header', [], [
	h('nav', ['left-nav'], [
		ha('a', [], {href: '/'}, [
			h('strong', [], ['Ink playground'])
		])
	])
	h('nav', ['right-nav'], [
		Link('Ink docs', 'https://dotink.co')
		Link('GitHub', 'https://github.com/thesephist/maverick')
	])
])

Editor := (
	` CodeMirror to TextArea plumbing `

	editorContainer := bind(document, 'createElement')('div')
	editorContainer.className := 'editorContainer'

	cmEditor := CodeMirror(editorContainer, {
		indentUnit: 4
		tabSize: 4
		lineWrapping: false
		lineNumbers: true
		indentWithTabs: true
		` provided by js/closebrackets.js addon `
		autoCloseBrackets: true
	})
	getValue := bind(cmEditor, 'getValue')
	setValue := bind(cmEditor, 'setValue')
	setOption := bind(cmEditor, 'setOption')

	setOption('extraKeys', {
		'Cmd-Enter': () => runRepl()
		'Ctrl-Enter': () => runRepl()
	})
	setOption('theme', str('maverick'))

	bind(cmEditor, 'on')('change', (_, changeEvt) => (
		State.file := getValue()
		persistFile()
		render()
	))
	requestAnimationFrame(() => requestAnimationFrame(() => (
		bind(cmEditor, 'refresh')()
	)))

	() => (
		State.file :: {
			getValue() -> ()
			` CodeMirror assumes string type arg `
			_ -> setValue(str(State.file))
		}

		h('div', ['editor'], [
			editorContainer
			RunButton()
		])
	)
)

AddToEditorButton := prog => hae('button', ['addToEditorButton'], {}, {
	click: evt => (
		bind(evt, 'stopPropagation')()
		render(State.file := State.file + Newline + prog + Newline)
	)
}, 'edit')

Repl := () => hae(
	'div'
	['repl']
	{}
	{
		click: () => focusReplLine()
	}
	[
		h('div', ['replTerm'], map(State.replLines, line => (
			h('div', ['replLine'], [
				line.type :: {
					Line.Prog -> hae('code', ['prog-line'], {}, {
						click: evt => (
							render(State.line := line.text)
							focusReplLine()
						)
					}, ['> ', line.text, AddToEditorButton(line.text)])
					Line.Result -> h('code', ['result-line'], [line.text])
					Line.Log -> h('code', ['log-line'], [line.text])
					Line.Error -> h('code', ['error-line'], [line.text])
				}
			])
		)))
		h('div', ['inputLine'], [
			h('div', ['inputPrompt'], ['> '])
			hae(
				'textarea'
				['replInputLine']
				{
					value: State.line
					autofocus: ~Embedded?
					placeholder: 'Type an expression to run'
				}
				{
					input: evt => (
						render(State.line := evt.target.value)
						inputEl := evt.target

						inputEl.style.height := 0
						normHeight := inputEl.scrollHeight :: {
							bind(inputEl, 'getBoundingClientRect')().height -> ()
							_ -> inputEl.style.height := string(normHeight) + 'px'
						}
					)
					keydown: evt => evt.key :: {
						'Enter' -> (
							bind(evt, 'preventDefault')()
							evt.ctrlKey | evt.metaKey :: {
								true -> runRepl()
								_ -> trim(State.line, ' ') :: {
									'' -> ()
									_ -> (
										State.replLines.len(State.replLines) := {
											type: Line.Prog
											text: State.line
										}
										evaluateInk(State.line)
										render(State.line := '')
										scrollToReplEnd()
									)
								}
							}
						)
						'l' -> evt.ctrlKey | evt.altKey :: {
							true -> render(State.replLines := [])
						}
					}
				}
				[]
			)
		])
	]
)

Credits := () => h('div', ['credits'], [
	'Ink playground is a project by '
	Link('Linus', 'https://thesephist.com/')
	' built with '
	Link('Ink', 'https://dotink.co/')
	' and '
	Link('September', 'https://github.com/thesephist/september')
])

` main render loop `

root := bind(document, 'querySelector')('#root')
r := Renderer(root)
update := r.update

State := {
	` editor content `
	file: restored := getItem('State.file') :: {
		() -> 'log(\'Hello, World!\')'
		_ -> restored
	}
	line: ''
	replLines: []
	theme: 'light'
}

` state fns `

clearRepl := () => render(State.replLines := [])

focusReplLine := () => replLine := bind(document, 'querySelector')('.replInputLine') :: {
	() -> ()
	_ -> bind(replLine, 'focus')()
}

runRepl := () => (
	State.replLines := []
	evaluateInk(State.file)
	render()
	scrollToReplEnd()
)

scrollToReplEnd := () => inputLine := bind(document, 'querySelector')('.replInputLine') :: {
	() -> ()
	_ -> bind(inputLine, 'scrollIntoView')()
}

persistFileImmediately := () => setItem('State.file', State.file)
persistFile := delay(persistFileImmediately, 800)

render := () => update(h('div', ['app'], [
	Embedded? :: {
		true -> ()
		_ -> Header()
	}
	h('div', ['workspace'], [
		Editor()
		Repl()
	])
	Credits()
]))

render()

