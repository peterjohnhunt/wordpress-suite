Debugger = require './debugger'
WPCLI = require './wpcli'
{requirePackages} = require 'atom-utils'
{CompositeDisposable} = require 'atom'

module.exports = class Wordpress
    constructor: (directory) ->
        @root          = directory
        @name          = @root.getBaseName()
        @paths         = []
        @messages      = []
        @subscriptions = new CompositeDisposable

        @subscriptions.add atom.commands.add '.project-root.wordpress > .header', 'wordpress-suite:root:open': => if @isSelected() then @openProjectRoot()
        @subscriptions.add atom.commands.add '.project-root.wordpress > .header', 'wordpress-suite:notifications:show': => if @isSelected() then @showNotifications()
        @subscriptions.add atom.commands.add '.project-root.wordpress > .header', 'wordpress-suite:notifications:clear': => if @isSelected() then @clearNotifications()

        atom.notifications.addSuccess(@name + ': Found' )

        requirePackages('tree-view','notifications').then ([treeView, notifications]) => @initialize([treeView, notifications])

    initialize: ([treeView, notifications]) ->
        @treeView = treeView.createView()
        @notifications = notifications

        @subscriptions.add atom.project.onDidChangePaths => @addClass('wordpress')

        @debug = new Debugger(@root)

        buttons = [
            {
                text: 'Clear',
                className: 'btn-clear',
                onDidClick: => @debug.clear()
            },
            {
                text: 'Open',
                className: 'btn-open',
                onDidClick: => @debug.open()
            }
        ]

        @subscriptions.add @debug.onDidInitialize => atom.notifications.addSuccess(@name + ": Watching")
        @subscriptions.add @debug.onDidDispose => atom.notifications.addWarning(@name + ": Stopped")
        @subscriptions.add @debug.onDidPause => atom.notifications.addWarning(@name + ": Paused Watching")
        @subscriptions.add @debug.onDidResume => atom.notifications.addSuccess(@name + ": Resumed Watching")
        @subscriptions.add @debug.onDidMessageInfo (message) => @messages.push(atom.notifications.addInfo(@name, { dismissable: true, detail: message, buttons: buttons }))
        @subscriptions.add @debug.onDidMessageNotice (message) => @messages.push(atom.notifications.addWarning(@name + ' | Notice', { dismissable: false, detail: message, buttons: buttons }))
        @subscriptions.add @debug.onDidMessageDeprecated (message) => @messages.push(atom.notifications.addWarning(@name + ' | Deprecation', { dismissable: false, detail: message, buttons: buttons }))
        @subscriptions.add @debug.onDidMessageError (message) => @messages.push(atom.notifications.addError(@name + ' | Error', { dismissable: true, detail: message, icon: 'bug', buttons: buttons }))

        @subscriptions.add atom.commands.add '.project-root.wordpress', 'wordpress-suite:debug:open': => if @isSelected() then @debug.open()
        @subscriptions.add atom.commands.add '.project-root.wordpress.watching', 'wordpress-suite:debug:pause': => if @isSelected() then @debug.pause()
        @subscriptions.add atom.commands.add '.project-root.wordpress:not(.watching)', 'wordpress-suite:debug:resume': => if @isSelected() then @debug.resume()

        @subscriptions.add @debug.onDidClear => @clearNotifications()

        @subscriptions.add @debug.onDidInitialize => @addClass('watching')
        @subscriptions.add @debug.onDidUpdate => if @debug.log.watching then @addClass('watching')

        @subscriptions.add @debug.onDidDispose => @removeClass('watching')
        @subscriptions.add @debug.onDidPause => @removeClass('watching')
        @subscriptions.add @debug.onDidResume => @addClass('watching')

        @wpcli = new WPCLI(@root)
        @subscriptions.add @wpcli.onDidWarning (message) => atom.notifications.addWarning(@name + ": CLI Warning", {dismissable: false, detail: message})
        @subscriptions.add @wpcli.onDidError (message) => atom.notifications.addError(@name + ": CLI Error", {dismissable: true, detail: message})
        @subscriptions.add @wpcli.onDidExport => atom.notifications.addSuccess(@name + ": Database Exported")

        @subscriptions.add atom.commands.add '.project-root.wordpress.cli > .header', 'wordpress-suite:cli:database:export': => if @isSelected() then @wpcli.export()

        @subscriptions.add @wpcli.onDidInitialize => @addClass('cli')
        @subscriptions.add @wpcli.onDidUpdate => if @wpcli.wp then @addClass('cli')

        @subscriptions.add @wpcli.onDidName (name) => @name = name

        @addClass('wordpress')

    isRelatedPath: (path) ->
        return @root.contains(path) or @root.getPath() == path

    addRelatedPath: (path) ->
        @paths.push(path)

    removeRelatedPath: (path) ->
        index = @paths.indexOf(path)
        @paths.splice(index,1)

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

    clearNotifications: ->
        for notification in @messages
            if notification.isDismissable() and not notification.isDismissed()
                notification.dismiss()
        @messages = []
        atom.notifications.addSuccess(@name + ": Cleared")

    showNotifications: ->
        if @messages.length == 0
            atom.notifications.addSuccess(@name + ': No Notifications')
            return

        for message in @messages
            el = atom.views.getView(message)
            el.classList.remove('remove')
            message.displayed = false
            message.dismissed = false
            @notifications.notificationsElement.appendChild(el)
            message.setDisplayed(true)

    isSelected: ->
        if @treeView
            for path in @paths
                if @treeView.entryForPath(path).classList.contains('selected')
                    return true

    dispose: ->
        @debug?.dispose()
        @wpcli?.dispose()
        @subscriptions?.dispose()
        atom.notifications.addWarning(@name + ': Removed')