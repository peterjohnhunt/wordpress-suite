Debugger = require './debugger'
WPCLI = require './wpcli'
path = require 'path'
{requirePackages} = require 'atom-utils'
{CompositeDisposable, Emitter, Directory, File} = require 'atom'

module.exports = class Wordpress
	constructor: (projectPath) ->
		@emitter   = new Emitter
		parent     = projectPath.split('wp-content', 1)[0]
		@root      = new Directory(parent)
		@name      = @root.getBaseName()
		@plugins   = []
		@wordpress = false
		@sitePaths = [projectPath]
		@messages  = []

		@subscriptions = new CompositeDisposable
		@subscriptions.add @root.onDidChange => @main()

		@subscriptions.add atom.project.onDidChangePaths => @checkSite()

		@subscriptions.add atom.project.onDidChangePaths =>
			if @wordpress? then @addClassAll('wordpress') else @removeClassAll('wordpress')
			if @messages?.length > 0 then @addClassAll('notifications') else @removeClassAll('notifications')
			if @wpcli?.initialized then @addClassAll('cli') else @removeClassAll('cli')
			if @wpcli?.installed then @addClassAll('installed') else @removeClassAll('installed')
			if @wpcli?.configured then @addClassAll('configured') else @removeClassAll('configured')
			if @wpcli?.checked then @addClassAll('checked') else @removeClassAll('checked')
			if @wpcli?.connected then @addClassAll('connected') else @removeClassAll('connected')
			if @debug?.initialized then @addClassAll('debug') else @removeClassAll('debug')
			if @debug?.watching then @addClassAll('watching') else @removeClassAll('watching')
			if @debug?.ignored.length > 0 then @addClassAll('ignored') else @removeClassAll('ignored')
			if @debug?.history then @addClassAll('contents') else @removeClassAll('contents')

		requirePackages('tree-view','notifications').then ([treeView, notifications]) =>
			@treeView = treeView.createView()
			@notifications = notifications

			@subscriptions.add @onIsWordpress (wordpress) => if wordpress then @addClassAll('wordpress') else @removeClassAll('wordpress')
			@subscriptions.add @onIsSite (site) => if site then @addClassAll('site') else @removeClassAll('site')
			@subscriptions.add @onIsNotifications (notifications) => if notifications then @addClassAll('notifications') else @removeClassAll('notifications')

			@subscriptions.add atom.commands.add '.wordpress:not(.site) > .header', 'wordpress-suite:site:open': => if @isSelected() then @addSite()
			@subscriptions.add atom.commands.add '.wordpress.notifications > .header', 'wordpress-suite:notifications:show': => if @isSelected() then @showNotifications()
			@subscriptions.add atom.commands.add '.wordpress.notifications > .header', 'wordpress-suite:notifications:clear': => if @isSelected() then @clearNotifications()
			@main()

			@wpcli = new WPCLI(@root)
			@subscriptions.add @wpcli.onIsCommand (exists) => if not exists and @wordpress then @addNotification('WP-CLI Could Not Be Found!', 'warning', {dismissable:true, detail:"WP CLI is not installed.\nFor additional features download and install wp-cli from: http://wp-cli.org/"})
			@subscriptions.add @wpcli.onDidError ([title, type, options]) => @addNotification(title, type, options)

			@subscriptions.add @wpcli.onIsInitialized (initialized) => if initialized then @addClassAll('cli') else @removeClassAll('cli')
			@subscriptions.add @wpcli.onIsInstalled (installed) => if installed then @addClassAll('installed') else @removeClassAll('installed')
			@subscriptions.add @wpcli.onIsConfigured (configured) => if configured then @addClassAll('configured') else @removeClassAll('configured')
			@subscriptions.add @wpcli.onIsChecked (checked) => if checked then @addClassAll('checked') else @removeClassAll('checked')
			@subscriptions.add @wpcli.onIsConnected (connected) => if connected then @addClassAll('connected') else @removeClassAll('connected')

			@subscriptions.add @wpcli.onDidName (name) => @name = name

			@subscriptions.add @wpcli.onDidDownload => @addNotification("Wordpress Downloaded")
			@subscriptions.add @wpcli.onDidConfig => @addNotification("Config Created")
			@subscriptions.add @wpcli.onDidCreate => @addNotification("DB Created")
			@subscriptions.add @wpcli.onDidInstall => @addNotification("Wordpress Installed")
			@subscriptions.add @wpcli.onDidExport => @addNotification("Database Exported")
			@subscriptions.add @wpcli.onDidImport => @addNotification("Database Imported")

			@subscriptions.add atom.commands.add '.project-root.cli:not(.installed)', 'wordpress-suite:cli:core:download': => if @isSelected() then @wpcli.download()
			@subscriptions.add atom.commands.add '.project-root.cli.installed:not(.configured)', 'wordpress-suite:cli:core:configure': => if @isSelected() then @wpcli.config()
			@subscriptions.add atom.commands.add '.project-root.cli.configured:not(.checked)', 'wordpress-suite:cli:db:create': => if @isSelected() then @wpcli.create()
			@subscriptions.add atom.commands.add '.project-root.cli.checked:not(.connected)', 'wordpress-suite:cli:core:install': => if @isSelected() then @wpcli.install()
			@subscriptions.add atom.commands.add '.project-root.cli.connected', 'wordpress-suite:cli:database:import': => if @isSelected() then @wpcli.import()
			@subscriptions.add atom.commands.add '.project-root.cli.connected', 'wordpress-suite:cli:database:export': => if @isSelected() then @wpcli.export()
			@wpcli.main()

			@debug = new Debugger(@root)
			@subscriptions.add @debug.onIsInitialized (initialized) => if initialized then @addClassAll('debug') else @removeClassAll('debug')
			@subscriptions.add @debug.onIsWatching (watching) => if watching then @addClassAll('watching') else @removeClassAll('watching')
			@subscriptions.add @debug.onIsIgnored (ignored) => if ignored then @addClassAll('ignored') else @removeClassAll('ignored')
			@subscriptions.add @debug.onIsContents (contents) => if contents then @addClassAll('contents') else @removeClassAll('contents')

			@subscriptions.add @debug.onDidLog ([title, type, options]) => @addNotification(title, type, options)
			@subscriptions.add @debug.onDidOpen => @clearNotifications()
			@subscriptions.add @debug.onDidClear => @clearNotifications()

			@subscriptions.add @debug.onDidIgnoredAdd => @addNotification("Message Ignored")
			@subscriptions.add @debug.onDidIgnoredClear => @addNotification("Ignore Cleared")

			@subscriptions.add atom.commands.add '.project-root.debug > .header', 'wordpress-suite:debug:open': => if @isSelected() then @debug.open()
			@subscriptions.add atom.commands.add '.project-root.debug.contents > .header', 'wordpress-suite:debug:clear': => if @isSelected() then @debug.clear()
			@subscriptions.add atom.commands.add '.project-root.debug.ignored > .header', 'wordpress-suite:debug:ignored': => if @isSelected() then @debug.ignore_clear()
			@subscriptions.add atom.commands.add '.project-root.debug.watching > .header', 'wordpress-suite:debug:pause': => if @isSelected() then @debug.pause()
			@subscriptions.add atom.commands.add '.project-root.debug:not(.watching) > .header', 'wordpress-suite:debug:resume': => if @isSelected() then @debug.resume()
			@debug.main()

	main: ->
		@checkSite()
		@checkWordpress()

	checkWordpress: ->
		@root.getSubdirectory('wp-content').exists().then (exists) =>
			if not @wordpress and exists
				@addNotification("Wordpress Site Found")
			@wordpress = exists
			@emitter.emit 'status:wordpress', @wordpress

	checkSite: ->
		@site = @root.getPath() in @sitePaths
		@emitter.emit 'status:site', @site

	addClass: (sitePath, classnames) ->
		if @treeView
			entry = @treeView.entryForPath(sitePath)
			if entry
				for classname in classnames.split(' ')
					entry.classList.add(classname)

	removeClass: (sitePath, classnames) ->
		if @treeView
			entry = @treeView.entryForPath(sitePath)
			if entry
				for classname in classnames.split(' ')
					entry.classList.remove(classname)

	addClassAll: (classname) ->
		for sitePath in @sitePaths
			@addClass(sitePath,classname)

	removeClassAll: (classname) ->
		for sitePath in @sitePaths
			@removeClass(sitePath,classname)

	isSelected: ->
		if @treeView
			for sitePath in @sitePaths
				if @treeView.entryForPath(sitePath)?.classList.contains('selected')
					return true

	isRelatedPath: (sitePath) ->
		return @root.contains(sitePath) or @root.getPath() == sitePath

	addRelatedPath: (sitePath) ->
		@sitePaths.push(sitePath)

	removeRelatedPath: (sitePath) ->
		index = @sitePaths.indexOf(sitePath)
		@sitePaths.splice(index,1)

	addSite: ->
		atom.project.addPath(@root.getPath())

	addPlugin: (plugin) ->
		console.log 'here'
		console.log plugin

	addNotification: (title='', type='success', options={dismissable:false}) ->
		title = if title then @name + ' | ' + title else @name

		notification = atom.notifications.add(type, title, options)

		if options.dismissable then @messages.push(notification)

		@emitter.emit 'status:notifications', @messages.length > 0

		@convertNotification(notification)
		@subscriptions.add notification.onDidDisplay (notification) => @convertNotification(notification)

	clearNotifications: ->
		for notification in @messages
			if notification.isDismissable() and not notification.isDismissed()
				notification.dismiss()
		@messages = []
		@emitter.emit 'status:notifications', @messages.length > 0

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

	onIsWordpress: (callback) ->
		@emitter.on('status:wordpress', callback)

	onIsSite: (callback) ->
		@emitter.on('status:site', callback)

	onIsNotifications: (callback) ->
		@emitter.on('status:notifications', callback)

	dispose: ->
		if @wordpress then @addNotification("Wordpress Site Removed")
		@removeClassAll('wordpress site notifications cli installed configured checked connected debug watching ignored contents')
		@wpcli?.dispose()
		@debug?.dispose()
		@subscriptions?.dispose()