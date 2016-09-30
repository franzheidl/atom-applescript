{exec} = require 'child_process'
{CompositeDisposable} = require 'atom'

module.exports =
	subs: null
	autoCompiling: false
	
	activate: ->
		name = "language-applescript"
		@subs = new CompositeDisposable()
		@subs.add atom.config.observe "#{name}.autoCompile", (newValue) =>
			@enableAutoCompile newValue
		
		@subs.add atom.commands.add "body", "#{name}:decompile", => @decompile()
		@subs.add atom.commands.add "body", "#{name}:recompile", => @recompile()

	deactivate: -> @subs.dispose()
	
#-------------------------------------------------------------------------------
	decompile: ->
		editor = atom.workspace.getActiveTextEditor()
		if path = editor?.buffer.getPath()
			task = exec "osadecompile '#{path}'"
			task.stdout.on "data", (data) -> editor.setText data
	
	recompile: ->
		editor = atom.workspace.getActiveTextEditor()
		if path = editor?.buffer.getPath()
			exec "osacompile -o #{path}{,}"

#-------------------------------------------------------------------------------
	enableAutoCompile: (enable) ->
		if enable and not @autoCompiling
			@autoCompiling = true
			
			@subs.add @watchEditors = atom.workspace.observeTextEditors (editor) =>
				scpt = editor.getPath()
				{scopeName} = editor.getGrammar()

				if scopeName.endsWith('applescript') and scpt?.endsWith '.scpt'

					# Decompile .scpt
					stdout = exec "osadecompile '#{scpt}'"
					stdout.stdout.on 'data', (data) -> editor.setText data

					# Recompile on save/close
					editor.onDidDestroy =>
						if @autoCompiling then exec "osacompile -o '#{scpt}'{,}"
			
		else if not enable
			@autoCompiling = false
			if @watchEditors?
				@watchEditors.dispose()
				@subs.remove @watchEditors
