WP = require 'wp-cli'
{CompositeDisposable, Emitter} = require 'atom'

module.exports = class Wordpress
    constructor: (directory) ->
        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add '.project-root.wordpress.cli > .header', 'atom-wordpress:cli:database:export': => @export()

        @emitter = new Emitter
        @root = directory

        WP.discover { path: @root.getPath() }, (wp) => @initialize(wp)

    initialize: (wp) ->
        @wp = wp

        @wp.cli.info (err,data) =>
            if err
                @emitter.emit 'error', err
            else
                @emitter.emit 'initialize'

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
        @emitter.emit 'dispose'
        @emitter.dispose()
        @subscriptions.dispose()

    onDidInitialize: (callback) ->
        @emitter.on('initialize', callback)

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