WP = require 'wp-cli'
command = require 'command-exists'
{CompositeDisposable, Emitter} = require 'atom'

module.exports = class WPCLI
    constructor: (directory) ->
        @emitter = new Emitter
        @root = directory

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.project.onDidChangePaths => @emitter.emit 'update'

        command 'wp', (err,exists) =>
            if not exists
                @emitter.emit 'error', 'WP CLI not installed'
            else
                @initialize()

    initialize: ->
        WP.discover { path: @root.getPath() }, (wp) =>
            @wp = wp

            @wp.option.get 'blogname', (err,data) =>
                if err
                    @emitter.emit 'error', err
                else
                    @emitter.emit 'name', data

            @wp.option.get 'home', (err,data) =>
                if err
                    @emitter.emit 'error', err
                else
                    @emitter.emit 'url', data

            @wp.plugin.list (err,data) =>
                if err
                    @emitter.emit 'error', err
                else
                    @emitter.emit 'plugin', data

            @emitter.emit 'initialize'

    export: ->
        exportPath = @root.getSubdirectory('db')
        exportPath.create().then (created) =>
            dbpath = exportPath.getPath() + '/latest-db.sql'
            @wp.db.export dbpath, (err,data) =>
                if err
                    @emitter.emit 'error', err
                else
                    @emitter.emit 'export', data

    dispose: ->
        @emitter?.emit 'dispose'
        @emitter?.dispose()
        @subscriptions?.dispose()

    onDidInitialize: (callback) ->
        @emitter.on('initialize', callback)

    onDidUpdate: (callback) ->
        @emitter.on('update', callback)

    onDidDispose: (callback) ->
        @emitter.on('dispose', callback)

    onDidName: (callback) ->
        @emitter.on('name', callback)

    onDidURL: (callback) ->
        @emitter.on('url', callback)

    onDidPlugin: (callback) ->
        @emitter.on('plugin', callback)

    onDidError: (callback) ->
        @emitter.on('error', callback)

    onDidExport: (callback) ->
        @emitter.on('export', callback)