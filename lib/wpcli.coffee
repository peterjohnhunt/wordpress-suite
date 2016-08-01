WP = require 'wp-cli'
{CompositeDisposable, Emitter} = require 'atom'

module.exports = class WPCLI
    constructor: (directory) ->
        @emitter = new Emitter
        @root = directory

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.project.onDidChangePaths => @emitter.emit 'update'

        WP.discover { path: @root.getPath() }, (wp) => @initialize(wp)

    initialize: (wp) ->
        wp.cli.info (err,data) =>
            if err
                @emitter.emit 'error', err
            else
                @emitter.emit 'initialize'

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

    onDidError: (callback) ->
        @emitter.on('error', callback)

    onDidExport: (callback) ->
        @emitter.on('export', callback)