{CompositeDisposable, Emitter} = require 'atom'

module.exports = class Debugger
    constructor: (directory) ->
        @emitter = new Emitter
        @root = directory

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.project.onDidChangePaths => @emitter.emit 'update'

        @initialize()

    initialize: ->
        if @log
            @subscriptions.dispose();

        @log = @root.getSubdirectory('wp-content').getFile('debug.log')
        @log.history = ''
        @log.recent = []
        @log.watching = true;

        @log.create().then (created) =>
            if not created
                @log.read().then (contents) =>
                    @log.history = contents
            @emitter.emit 'initialize'

        @subscriptions.add @log.onDidChange => @change()
        @subscriptions.add @log.onDidRename => @initialize()
        @subscriptions.add @log.onDidDelete => @initialize()

    open: ->
        atom.workspace.open(@log.getPath(), {pending:false, searchAllPanes:true})

    clear: ->
        @log.write('')
        @log.history = ''
        @log.recent = []
        @emitter.emit 'clear'

    pause: ->
        @log.watching = false;
        @emitter.emit 'pause'

    resume: ->
        @log.watching = true;
        @emitter.emit 'resume'

    change: ->
        return unless @log.watching?

        @log.read().then (contents) =>
            if contents.length >= @log.history.length
                messages = contents.replace(@log.history,'').split(/^\[\d{2}-\w{3}-\d{4} \d{2}:\d{2}:\d{2} UTC\] /gm)
                for message in messages
                    if message isnt ''
                        if message.indexOf('PHP Parse error:') == 0
                            @emitter.emit 'message:error', message
                        else if message.indexOf('PHP Notice:') == 0
                            @emitter.emit 'message:notice', message
                        else
                            @emitter.emit 'message:info', message
            @log.history = contents

    dispose: ->
        @emitter?.emit 'dispose'
        @emitter?.dispose()
        @subscriptions?.dispose()

    onDidInitialize: (callback) ->
        @emitter.on('initialize', callback)

    onDidUpdate: (callback) ->
        @emitter.on('update', callback)

    onDidClear: (callback) ->
        @emitter.on('clear', callback)

    onDidPause: (callback) ->
        @emitter.on('pause', callback)

    onDidResume: (callback) ->
        @emitter.on('resume', callback)

    onDidMessageInfo: (callback) ->
        @emitter.on('message:info', callback)

    onDidMessageNotice: (callback) ->
        @emitter.on('message:notice', callback)

    onDidMessageError: (callback) ->
        @emitter.on('message:error', callback)

    onDidMessageNone: (callback) ->
        @emitter.on('message:none', callback)

    onDidDispose: (callback) ->
        @emitter.on('dispose', callback)