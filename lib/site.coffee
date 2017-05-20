{CompositeDisposable, Disposable, Directory} = require 'atom'
path = require 'path'

WPCLI = require './wpcli'
Notifications = require './notifications'
LogFile = require './log-file'

module.exports = class Site

	constructor: (sitePath,logger) ->
		@root          = sitePath.split('\/wp-content', 1).shift()
		@directory     = new Directory(@root)
		@name          = @directory.getBaseName()
		@logger        = logger
		@log           = @logger "site.#{@name}"
		@paths         = [sitePath]
		@subscriptions = new CompositeDisposable
		@treeView      = atom.workspace.getLeftDock().getActivePaneItem()

		@setup()

	refresh: ->
		@notifications.add("#{@name.toUpperCase()} | Refreshing", 'info')
		@subscriptions?.dispose()
		@notifications = null
		@logFile = null
		@wpcli = null
		@subscriptions = new CompositeDisposable

		@setup()

	setup: ->
		@subscriptions.add @logFile       = new LogFile(@root,@logger,@name)
		@subscriptions.add @wpcli         = new WPCLI(@root,@logger,@name)
		@subscriptions.add @notifications = new Notifications(@logger,@name)

		@subscriptions.add @logFile.onNotification ([title,type]) => @notifications.add("#{@name.toUpperCase()} | #{title}", type)
		@subscriptions.add @logFile.onMessage ([title,type,detail]) =>
			options = {
				sitePath: @root,
				dismissable:true,
				detail: detail,
				buttons: [
					{ text: 'Clear', className: 'btn-clear', onDidClick: =>
						@logFile.clear()
						@notifications.clear()
					},
					{ text: 'Open', className: 'btn-open', onDidClick: =>
						@logFile.open()
						@notifications.clear()
					},
					{ className: 'btn-mute btn-right', onDidClick: ->
						sitePath = @model.options.sitePath
						message = @model.options.detail
						atom.wordpressSuite.muteNotification(message, sitePath)
						@removeNotification()
					}
				]
			}
			@notifications.add("#{@name.toUpperCase()} | #{title}", type, options)

		@subscriptions.add @wpcli.onNotification ([title,type]) => @notifications.add("#{@name.toUpperCase()} | #{title}", type)
		@subscriptions.add @wpcli.onMessage ([title,type,detail]) =>
			options = {
				sitePath: @root,
				dismissable:true,
				detail: detail,
				buttons: [
					{ text: 'Clear', className: 'btn-clear', onDidClick: =>
						@notifications.clear()
					}
				]
			}
			@notifications.add("#{@name.toUpperCase()} | #{title}", type, options)

		@subscriptions.add @notifications.onNotification ([title,type]) => @notifications.add("#{@name.toUpperCase()} | #{title}", type, {dismissable:false}, true)
		@subscriptions.add @notifications.onMute ([title,type,detail]) =>
			options = {
				sitePath: @root,
				dismissable:true,
				detail: detail,
				buttons: [
					{ text: 'Clear', className: 'btn-clear', onDidClick: =>
						@notifications.clear()
					},
					{ className: 'btn-unmute btn-right', onDidClick: ->
						sitePath = @model.options.sitePath
						message = @model.options.detail
						atom.wordpressSuite.unmuteNotification(message, sitePath)
						@removeNotification()
					}
				]
			}
			@notifications.add("#{@name.toUpperCase()} | #{title}", type, options, true)

		@subscriptions.add @notifications.onUnmute ([title,type,detail]) =>
			options = {
				sitePath: @root,
				dismissable:true,
				detail: detail,
				buttons: [
					{ text: 'Clear', className: 'btn-clear', onDidClick: =>
						@notifications.clear()
					},
					{ className: 'btn-mute btn-right', onDidClick: ->
						sitePath = @model.options.sitePath
						message = @model.options.detail
						atom.wordpressSuite.muteNotification(message, sitePath)
						@removeNotification()
					}
				]
			}
			@notifications.add("#{@name.toUpperCase()} | #{title}", type, options)

		@log "Created | #{@name}", 6

		new Disposable()

	addPath: (sitePath) ->
		index = @paths.indexOf(sitePath)
		if index = -1
			@paths.push(sitePath)
			@log "Added Path | #{sitePath}", 6

	removePath: (sitePath) ->
		index = @paths.indexOf(sitePath)
		if index > -1
			@paths.splice(index,1)
			@log "Removed Path | #{sitePath}", 6

	containsPath: (sitePath) ->
		return @directory.contains(sitePath) or @root == sitePath

	hasPath: (sitePath) ->
		return @paths.indexOf(sitePath) > -1

	hasPaths: ->
		return @paths.length > 0

	isSelected: ->
		for sitePath in @paths
			element = @treeView.entryForPath(sitePath)
			if element
				if element.classList.contains('selected') or element.querySelector('.selected')
					return true

	getSelectedFile: ->
		for sitePath in @paths
			element = @treeView.entryForPath(sitePath)
			if element
				return element.querySelector('.selected')

	addRoot: ->
		atom.project.addPath(@root)
		@notifications.add("#{@name.toUpperCase()} | Added Root")

	hasRoot: ->
		return @hasPath(@root)

	hasWPCLI: (property) ->
		return @wpcli.status[property]

	hasLogFile: ->
		return @logFile.file

	isWatchingLogFile: ->
		return @logFile.watching

	logFileHasMessages: ->
		return @logFile.contents.length > 0

	hasNotifications: ->
		return @notifications.messages.length > 0

	hasMutedNotifications: ->
		return @notifications.muted.length > 0

	notificationsIsEnabled: ->
		return @notifications.enabled

	dispose: ->
		@log "Removed | #{@name}", 6

		@subscriptions?.dispose()

		if atom.inDevMode()
			@logger = -> ->
			@log = ->
			@root = null
			@directory = null
			@name = null
			@paths = null
			@notifications = null
			@logFile = null
			@wpcli = null
			@treeView = null
			@subscriptions = null
