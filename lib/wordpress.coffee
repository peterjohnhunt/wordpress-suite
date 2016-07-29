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

        @subscriptions.add atom.commands.add '.project-root.wordpress > .header', 'atom-wordpress:root:open': => @openProjectRoot()
        @subscriptions.add atom.commands.add '.project-root.wordpress > .header', 'atom-wordpress:notifications:show': => @showNotifications()
        @subscriptions.add atom.commands.add '.project-root.wordpress > .header', 'atom-wordpress:notifications:clear': => @clearNotifications()

        atom.notifications.addSuccess(@name + ': Found' )

        requirePackages('tree-view','notifications').then ([treeView, notifications]) => @initialize([treeView, notifications])

    initialize: ([treeView, notifications]) ->
        @treeView = treeView.createView()
        @notifications = notifications

        @subscriptions.add atom.project.onDidChangePaths => @addClass('wordpress')

        @debugger = new Debugger(@root)
        @subscriptions.add @debugger.onDidInitialize => atom.notifications.addSuccess(@name + ": Watching")
        @subscriptions.add @debugger.onDidDispose => atom.notifications.addWarning(@name + ": Stopped")
        @subscriptions.add @debugger.onDidPause => atom.notifications.addWarning(@name + ": Paused Watching")
        @subscriptions.add @debugger.onDidResume => atom.notifications.addSuccess(@name + ": Resumed Watching")
        @subscriptions.add @debugger.onDidMessageInfo (message) => @messages.push(atom.notifications.addInfo(@name, { dismissable: true, detail: message, buttons: [ { text: 'Clear', className: 'btn-clear', onDidClick: => @debugger.clear() }, { text: 'Open', className: 'btn-open', onDidClick: => @debugger.open() } ] }))
        @subscriptions.add @debugger.onDidMessageNotice (message) => @messages.push(atom.notifications.addWarning(@name, { dismissable: true, detail: message, buttons: [ { text: 'Clear', className: 'btn-clear', onDidClick: => @debugger.clear() }, { text: 'Open', className: 'btn-open', onDidClick: => @debugger.open() } ] }))
        @subscriptions.add @debugger.onDidMessageError (message) => @messages.push(atom.notifications.addError(@name, { dismissable: true, detail: message, icon: 'bug', buttons: [ { text: 'Clear', className: 'btn-clear', onDidClick: => @debugger.clear() }, { text: 'Open', className: 'btn-open', onDidClick: => @debugger.open() } ] }))

        @subscriptions.add @debugger.onDidClear => @clearNotifications()

        @subscriptions.add @debugger.onDidInitialize => @addClass('watching')
        @subscriptions.add @debugger.onDidDispose => @removeClass('watching')
        @subscriptions.add @debugger.onDidPause => @removeClass('watching')
        @subscriptions.add @debugger.onDidResume => @addClass('watching')

        @subscriptions.add atom.project.onDidChangePaths => @debugger.initialize()

        @wpcli = new WPCLI(@root)

        @subscriptions.add @wpcli.onDidError (message) => atom.notifications.addError(@name + ": CLI Error", {dismissable: true, detail: message})
        @subscriptions.add @wpcli.onDidExport => atom.notifications.addSuccess(@name + ": Database Exported")

        @subscriptions.add @wpcli.onDidInitialize => @addClass('cli')

        @subscriptions.add @wpcli.onDidName (name) => @name = name

        @subscriptions.add atom.project.onDidChangePaths => @debugger.initialize()

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

    dispose: ->
        @debug?.dispose()
        @subscriptions?.dispose()
        atom.notifications.addWarning('Removed Wordpress Site: ' + @name)