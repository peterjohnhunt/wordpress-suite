{CompositeDisposable, Disposable, Emitter} = require 'atom'
{requirePackages} = require 'atom-utils'
path = require 'path'

module.exports = class Notifications

	constructor: (logger,namespace) ->
		@logger = logger
		@log    = @logger "site.#{namespace}.notifications"

		@enabled  = atom.config.get('wordpress-suite.features.notifications')

		@messages = []
		@muted    = []
		@notifications = null

		@emitter = new Emitter

		@subscriptions = new CompositeDisposable

		@setup()

		@log "Created", 6

		new Disposable()

	refresh: ->
		@subscriptions?.dispose()
		@enabled  = atom.config.get('wordpress-suite.features.notifications')
		@messages = []
		@muted    = []
		@notifications = null
		@subscriptions = new CompositeDisposable
		@setup()

	setup: ->
		requirePackages('notifications').then ([notifications]) =>
			@notifications = notifications

	enable: ->
		@enabled = true
		@emitter.emit 'notification', [ 'Notifications Enabled', 'success' ]

	disable: ->
		@enabled = false
		@emitter.emit 'notification', [ 'Notifications Disabled', 'warning' ]

	add: (title, type='success', options={dismissable:false}, force) ->
		if force or (@enabled and @muted.indexOf(options.detail) is -1)
			notification = atom.notifications.add(type, title, options)

			if not force and options.dismissable
				@messages.push(notification)

			@subscriptions.add notification.onDidDisplay (notification) => @convert(notification)

			@convert(notification)

	show: ->
		@notifications.lastNotification = null
		for message in @messages
			element = atom.views.getView(message).element
			element.classList.remove('remove')
			message.dismissed = false if message.isDismissable()
			message.displayed = false
			@notifications.addNotificationView(message)

	clear: ->
		for notification in @messages
			if notification.isDismissable() and not notification.isDismissed()
				notification.dismiss()
		@messages = []

	convert: (notification) ->
		notification = atom.views.getView(notification)
		lines = notification.element.querySelectorAll('.detail-content .line')
		for line in lines
			link = line.innerText.match(/\s+in\s(\/.*\.php) on line (\d+)/)
			if link
				line.innerText = link.input.replace(link[0], ' ')
				link = @link(link)
				line.appendChild(link)

	link: (rawLink) ->
		link = document.createElement('a')
		link.innerText = 'in ' + path.basename(rawLink[1]) + ' on line ' + rawLink[2]
		link.dataset.sitePath = rawLink[1]
		link.dataset.line = rawLink[2]
		link.addEventListener 'click', (event) ->
			event.preventDefault()
			atom.workspace.open(@.dataset.sitePath, {pending: false, initialLine: (parseInt(@.dataset.line) - 1), searchAllPanes:true})
		return link

	mute: (message) ->
		@muted.push(message)
		@emitter.emit 'mute', [ 'Muted Notification', 'success', message ]

	unmute: (message) ->
		index = @muted.indexOf(message)
		if index > -1
			@muted.splice(index,1);
			@emitter.emit 'unmute', [ 'Unmuted Notification', 'success', message ]

	showMuted: ->
		for message in @muted
			@emitter.emit 'mute', [ 'Muted Notification', 'warning', message ]

	clearMuted: ->
		@muted = []
		@emitter.emit 'notification', [ 'Cleared Muted Notification', 'success' ]

	onNotification: (callback) ->
		@emitter.on('notification', callback)

	onMute: (callback) ->
		@emitter.on('mute', callback)

	onUnmute: (callback) ->
		@emitter.on('unmute', callback)

	dispose: ->
		@log "Removed", 6

		@subscriptions?.dispose()

		if atom.inDevMode()
			@logger = -> ->
			@log = ->
			@messages = []
			@muted = []
			@enabled = null
			@notifications = null
			@emitter = null