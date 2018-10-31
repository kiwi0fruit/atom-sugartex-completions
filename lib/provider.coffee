fs = require 'fs'
path = require 'path'
fuzzaldrinPlus = require 'fuzzaldrin-plus'

module.exports =
  filterSuggestions: false
  suggestionPriority: 5
  inclusionPriority: 5

  textEditorSelectors: 'atom-text-editor'
  getTextEditorSelector: -> @textEditorSelectors

  completions: {}

  texPattern: /\\(.*)$/

  activate: ->
    @disposable = atom.config.observe 'latex-completions.boostGreekCharacters', (boost) =>
      @boostGreek = boost

  deactivate: ->
    @disposable.dispose()

  load: (p) ->
    @scopeSelector = atom.config.get("sugartex-completions.selector")
    @disableForScopeSelector = atom.config.get("sugartex-completions.disableForSelector")
    return if p == ''
    p ?= path.resolve(__dirname, '..', 'completions', 'completions.json')
    fs.readFile p, (error, content) =>
      return if error?
      for name, char of JSON.parse(content)
        @completions[name] = char

  score: (a, b, symbol) ->
    s = fuzzaldrinPlus.score(a, b)
    if @boostGreek && /[Α-ϵ]/.test(symbol)
      s = s * 1.4
    s

  compare: (a, b) ->
    diff = b.score - a.score

    if diff == 0
      a.leftLabel.localeCompare(b.leftLabel)
    else
      diff

  getSuggestions: ({bufferPosition, editor, prefix}) ->
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    prefix = line.match(@texPattern)?[1]
    return new Promise (resolve) =>
      if prefix?
        resolve(({text, leftLabel, replacementPrefix: prefix, score: @score(text, prefix, leftLabel)} for text, leftLabel of @completions).sort(@compare))
      else
        resolve([])

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
    word = suggestion.text
    editor.selectLeft(word.length + 1)
    editor.insertText(@completions[word])
