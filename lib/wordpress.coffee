Debugger = require './debugger'
WPCLI = require './wpcli'
path = require 'path'
{requirePackages} = require 'atom-utils'
{CompositeDisposable} = require 'atom'

module.exports = class Wordpress
	constructor: (directory) ->
		@root          = directory
		@name          = @root.getBaseName()
		@sitePaths     = []
		@messages      = []
		@subscriptions = new CompositeDisposable

		@subscriptions.add atom.commands.add '.project-root.wordpress > .header', 'wordpress-suite:root:open': => if @isSelected() then @openProjectRoot()
		@subscriptions.add atom.commands.add '.project-root.wordpress > .header', 'wordpress-suite:notifications:show': => if @isSelected() then @showNotifications()

		atom.notifications.addSuccess(@name + ': Initialized' )

		requirePackages('tree-view','notifications').then ([treeView, notifications]) => @initialize([treeView, notifications])

	initialize: ([treeView, notifications]) ->
		@treeView = treeView.createView()
		@notifications = notifications

		@addClass('wordpress')
		@subscriptions.add atom.project.onDidChangePaths => @addClass('wordpress')

		@debug = new Debugger(@root)
		@subscriptions.add @debug.onDidPause => atom.notifications.addWarning(@name + ": Paused Watching")
		@subscriptions.add @debug.onDidResume => atom.notifications.addSuccess(@name + ": Resumed Watching")
		@subscriptions.add @debug.onDidMessageInfo (message) => @addNotification(message, 'Info', atom.config.get('wordpress-suite.notifications.info.autodismiss'))
		@subscriptions.add @debug.onDidMessageNotice (message) => @addNotification(message, 'Notice', atom.config.get('wordpress-suite.notifications.notice.autodismiss'))
		@subscriptions.add @debug.onDidMessageDeprecation (message) => @addNotification(message, 'Deprecation', atom.config.get('wordpress-suite.notifications.deprecation.autodismiss'))
		@subscriptions.add @debug.onDidMessageWarning (message) => @addNotification(message, 'Warning', atom.config.get('wordpress-suite.notifications.warning.autodismiss'))
		@subscriptions.add @debug.onDidMessageError (message) => @addNotification(message, 'Error', atom.config.get('wordpress-suite.notifications.error.autodismiss'))
		@subscriptions.add @debug.onDidMessageIgnored => atom.notifications.addSuccess(@name + ": Message Ignored")
		@subscriptions.add @debug.onDidClearIgnored => atom.notifications.addSuccess(@name + ": Ignore Cleared")
		@subscriptions.add @debug.onDidClear => @clearNotifications() and atom.notifications.addSuccess(@name + ": Cleared")
		@subscriptions.add @debug.onDidInitialize => @addClass('watching')
		@subscriptions.add @debug.onDidUpdate => if @debug.log.watching then @addClass('watching')
		@subscriptions.add @debug.onDidDispose => @removeClass('watching')
		@subscriptions.add @debug.onDidPause => @removeClass('watching')
		@subscriptions.add @debug.onDidResume => @addClass('watching')
		@subscriptions.add atom.commands.add '.project-root.wordpress > .header', 'wordpress-suite:debug:open': => if @isSelected() then @debug.open()
		@subscriptions.add atom.commands.add '.project-root.wordpress > .header', 'wordpress-suite:debug:clear': => if @isSelected() then @debug.clear()
		@subscriptions.add atom.commands.add '.project-root.wordpress.watching > .header', 'wordpress-suite:debug:pause': => if @isSelected() then @debug.pause()
		@subscriptions.add atom.commands.add '.project-root.wordpress:not(.watching) > .header', 'wordpress-suite:debug:resume': => if @isSelected() then @debug.resume()
		@subscriptions.add atom.commands.add '.project-root.wordpress > .header', 'wordpress-suite:debug:clearIgnored': => if @isSelected() then @debug.clearIgnored()

		@wpcli = new WPCLI(@root)
		@subscriptions.add @wpcli.onDidWarning (message) => atom.notifications.addWarning(@name + ": CLI Warning", {dismissable: false, detail: message})
		@subscriptions.add @wpcli.onDidError (message) => atom.notifications.addError(@name + ": CLI Error", {dismissable: false, detail: message})
		@subscriptions.add @wpcli.onDidExport => atom.notifications.addSuccess(@name + ": Database Exported")
		@subscriptions.add @wpcli.onDidInitialize => @addClass('cli')
		@subscriptions.add @wpcli.onDidUpdate => if @wpcli.wp then @addClass('cli')
		@subscriptions.add @wpcli.onDidName (name) => @name = name
		@subscriptions.add atom.commands.add '.project-root.wordpress.cli > .header', 'wordpress-suite:cli:database:export': => if @isSelected() then @wpcli.export()

	isSelected: ->
		if @treeView
			for sitePath in @sitePaths
				if @treeView.entryForPath(sitePath).classList.contains('selected')
					return true

	isRelatedPath: (sitePath) ->
		return @root.contains(sitePath) or @root.getPath() == sitePath

	addRelatedPath: (sitePath) ->
		@sitePaths.push(sitePath)

	removeRelatedPath: (sitePath) ->
		index = @sitePaths.indexOf(sitePath)
		@sitePaths.splice(index,1)

	openProjectRoot: ->
		atom.project.addPath(@root.getPath())

	addClass: (classname) ->
		for sitePath in @sitePaths
			if @treeView
				@treeView.entryForPath(sitePath)?.classList.add(classname)

	removeClass: (classname) ->
		for sitePath in @sitePaths
			if @treeView
				@treeView.entryForPath(sitePath)?.classList.remove(classname)

	addNotification: (message, type, autodismiss) ->
		buttons = [
			{
				text: 'Clear',
				className: 'btn-clear',
				onDidClick: =>
					@clearNotifications()
					@debug.clear()
			},
			{
				text: 'Open',
				className: 'btn-open',
				onDidClick: =>
					@clearNotifications()
					@debug.open()
			},
			{
				className: 'btn-ignore btn-right',
				onDidClick: (event) =>
					notification = event.target.parentElement.parentElement.parentElement.parentElement.model
					message = notification.getDetail()
					notification.dismiss()
					@debug.ignore(message)
			}
		]

		options = {
			detail: message,
			dismissable: !autodismiss,
			buttons: buttons,
		}

		if type is 'Notice' or type is 'Deprecation' or type is 'Warning'
			notification = atom.notifications.addWarning(@name + ' | ' + type, options)
		else if type is 'Error'
			notification = atom.notifications.addError(@name + ' | ' + type, options)
		else
			notification = atom.notifications.addInfo(@name, options)

		@messages.push(notification)

		@convertNotification(notification)

		@subscriptions.add notification.onDidDisplay (notification) => @convertNotification(notification)

	clearNotifications: ->
		for notification in @messages
			if notification.isDismissable() and not notification.isDismissed()
				notification.dismiss()
		@messages = []

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
			if not message.isDismissable()
				message.autohide()

	convertNotification: (notification) ->
		element = atom.views.getView(notification)
		lines = element.querySelectorAll('.detail-content .line')
		for line in lines
			link = line.innerText.match(/\s+in\s(\/.*\.php) on line (\d+)/)
			if link
				line.innerText = link.input.replace(link[0], ' ')
				link = @convertLink(link)
				line.appendChild(link)

	convertLink: (rawLink) ->
		link = document.createElement('a')
		link.innerText = 'in ' + path.basename(rawLink[1]) + ' on line ' + rawLink[2]
		link.dataset.sitePath = rawLink[1]
		link.dataset.line = rawLink[2]
		link.addEventListener 'click', (event) ->
			event.preventDefault()
			atom.workspace.open(@.dataset.sitePath, {pending: false, initialLine: (parseInt(@.dataset.line) - 1), searchAllPanes:true})
		return link

	dispose: ->
		@debug?.dispose()
		@wpcli?.dispose()
		@subscriptions?.dispose()
		atom.notifications.addWarning(@name + ': Removed')