WP = require 'wp-cli'
{requirePackages} = require 'atom-utils'
{CompositeDisposable} = require 'atom'

module.exports = class Wordpress
    constructor: (directory) ->
        @root          = directory
        @name          = @root.getBaseName()
        @paths         = []
        @subscriptions = new CompositeDisposable

        @subscriptions.add atom.commands.add '.project-root.wordpress > .header', 'atom-wordpress:openProjectRoot': => @openProjectRoot()

        atom.notifications.addSuccess('Found Wordpress Site: ' + @name)

        requirePackages('tree-view').then ([treeView]) =>
            @treeView = treeView.createView()
            @addClass('wordpress')
            @initialize()

    isRelatedPath: (path) ->
        return @root.contains(path) or @root.getPath() == path

    addRelatedPath: (path) ->
        @paths.push(path)
        if @treeView
            @treeView.entryForPath(path)?.classList.add('wordpress')
            if @wp
                @treeView.entryForPath(path)?.classList.add('cli')

    removeRelatedPath: (path) ->
        index = @paths.indexOf(path)
        @paths.splice(index,1)
        if @treeView
            @treeView.entryForPath(path)?.classList.remove('wordpress')
            if @wp
                @treeView.entryForPath(path)?.classList.remove('cli')

    openProjectRoot: ->
        atom.project.addPath(@root.getPath())

    addClass: (classname) ->
        for path in @paths
            if @treeView
                @treeView.entryForPath(path)?.classList.add(classname)

    removeClass: (classname) ->
        for path in @paths
            if @treeView
                @treeView.entryForPath(path)?.classList.remove(classname)

    initialize: ->
        @initialize_debug()
        WP.discover { path: @root.getPath() }, (CLI) =>
            CLI.cli.info (err,info) =>
                if err
                    atom.notifications.addWarning('WP-CLI not installed!')
                    return
                @initialize_cli(CLI)

    initialize_cli: (CLI) ->
        # Initialize
        @wp = CLI
        @addClass('cli')

        # Get Site Details
        @wp.option.get 'blogname', (err,blogname) =>
            @name = blogname
            atom.notifications.addSuccess(@name + " Initialized!")

        # Add Commands
        @subscriptions.add atom.commands.add '.project-root.wordpress.cli > .header', 'atom-wordpress:exportDatabase': => @cli_export()

    cli_export: ->
        dbFolder = @root.getSubdirectory('db')
        dbFolder.create().then (created) =>
            dbpath = dbFolder.getPath() + '/latest-db.sql'
            @wp.db.export dbpath, (err,message) =>
                if err
                    return
                atom.notifications.addSuccess('Database Exported: ' + @name)

    initialize_debug: ->
        @debug = {
            watching: true,
            notifications: [],
            history: '',
            unread: []
        }
        @addClass('watching')
        @debug.notifications.push(atom.notifications.addSuccess("Watching Debug Log: " + @name))

        # Initialize Log File
        @debug_create()

        # Add Commands
        @subscriptions.add atom.commands.add '.project-root.wordpress', 'atom-wordpress:openDebugLog': => @debug_open()
        @subscriptions.add atom.commands.add '.project-root.wordpress.watching', 'atom-wordpress:showRecent': => @debug_showRecent()
        @subscriptions.add atom.commands.add '.project-root.wordpress.watching', 'atom-wordpress:pauseWatchDebugLog': => @debug_pauseWatch()
        @subscriptions.add atom.commands.add '.project-root.wordpress:not(.watching)', 'atom-wordpress:resumeWatchDebugLog': => @debug_resumeWatch()

    debug_create: ->
        if @debug.log
            @debug.subscriptions.dispose()
            @debug.notifications.push(atom.notifications.addSuccess('Debug Log Cleared: ' + @name))

        @debug.log = @root.getSubdirectory('wp-content').getFile('debug.log')
        @debug.log.create().then (created) =>
            if not created
                @debug.log.read().then (contents) =>
                    @debug.history = contents

            # Subscriptions
            @debug.subscriptions = new CompositeDisposable
            @debug.subscriptions.add @debug.log.onDidChange => @debug_onChange()
            @debug.subscriptions.add @debug.log.onDidRename => @debug_create()
            @debug.subscriptions.add @debug.log.onDidDelete => @debug_create()

    debug_open: ->
        atom.workspace.open(@debug.log.getPath(), {pending:false, searchAllPanes:true})

    debug_clear: ->
        @debug_dimissAll()
        @debug.log.write('')
        @debug.history = ''
        @debug.unread = []
        @debug.notifications.push(atom.notifications.addSuccess('Debug Log Cleared: ' + @name))

    debug_dimissAll: ->
        for notification in @debug.notifications
            if notification.isDismissable() and not notification.isDismissed()
                notification.dismiss()
        @debug.notifications = []

    debug_pauseWatch: ->
        @debug.watching = false
        @removeClass('watching')
        @debug.notifications.push(atom.notifications.addSuccess("Paused Watching Debug Log: " + @name))

    debug_resumeWatch: ->
        @debug.watching = true
        @addClass('watching')
        @debug.notifications.push(atom.notifications.addSuccess("Resumed Watching Debug Log: " + @name))

    debug_onChange: ->
        if @debug.watching is false
            return
        @debug.log.read().then (contents) =>
            if contents.length > @debug.history.length
                @debug.unread = contents.replace(@debug.history,'').split(/^\[\d{2}-\w{3}-\d{4} \d{2}:\d{2}:\d{2} UTC\] /gm)
                @debug_showRecent()
            if contents is ''
                @debug_dimissAll()
                @debug.notifications.push(atom.notifications.addSuccess('Debug Log Cleared: ' + @name))
            @debug.history = contents

    debug_showRecent: ->
        if not @debug.unread
            @debug.notifications.push(atom.notifications.addSuccess('No Notifications: ' + @name))

        if not @debug.watching
            return

        for message in @debug.unread
            if message isnt ''
                if message.indexOf('PHP Parse error:') == 0
                    @debug_error(message)
                else if message.indexOf('PHP Notice:') == 0
                    @debug_notice(message)
                else
                    @debug_info(message)

    debug_error: (message) ->
        @debug.notifications.push(atom.notifications.addError(@name + ' Parse Error:', { dismissable: true, detail: message, icon: 'bug', buttons: [{ text: 'Clear', className: 'btn-clear', onDidClick: => @debug_clear() }, { text: 'Open', className: 'btn-open', onDidClick: => @debug_open() }] }))

    debug_notice: (message) ->
        @debug.notifications.push(atom.notifications.addWarning(@name + ' Notice:', { dismissable: true, detail: message, buttons: [{ text: 'Clear', className: 'btn-clear', onDidClick: => @debug_clear() }, { text: 'Open', className: 'btn-open', onDidClick: => @debug_open() }] }))

    debug_info: (message) ->
        @debug.notifications.push(atom.notifications.addInfo(@name + ' Logged:', { dismissable: true, detail: message, buttons: [{ text: 'Clear', className: 'btn-clear', onDidClick: => @debug_clear() }, { text: 'Open', className: 'btn-open', onDidClick: => @debug_open() }] }))

    dispose: ->
        @subscriptions?.dispose()
        @debug?.subscriptions?.dispose()
        atom.notifications.addWarning('Removed Wordpress Site: ' + @name)