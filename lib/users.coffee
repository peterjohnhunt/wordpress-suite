{CompositeDisposable, Emitter, Disposable, Directory} = require 'atom'

module.exports = class Users

	constructor: (wp,logger,namespace) ->
		@namespace = namespace
		@logger = logger
		@log    = @logger "site.#{@namespace}.wpcli.users"
		@wp     = wp

		@directory = null
		@menu = []
		@enabled = atom.config.get('wordpress-suite.features.users')

		@emitter = new Emitter

		@subscriptions = new CompositeDisposable

		@setup()

		new Disposable()

	refresh: ->
		@subscriptions?.dispose()
		@menu = []
		@subscriptions = new CompositeDisposable
		@setup()

	enable: ->
		@enabled = true
		@emitter.emit 'notification', [ 'WP-CLI Users Enabled', 'success' ]
		@refresh()

	disable: ->
		@enabled = false
		@emitter.emit 'notification', [ 'WP-CLI Users Disabled', 'warning' ]
		@refresh()

	setup: ->
		if @enabled
			@wp.user.list (err,users) =>
				if not err
					for user in users
						@subscriptions.add atom.commands.add ".project-root",
							"wordpress-suite:site:user:delete:#{@namespace}:#{user.user_login}": (event) =>
								name = event.type.split(':').pop()
								site = atom.wordpressSuite.getSelectedSite().wpcli.users.delete(name)

						submenu = []

						submenu.push({ label: 'Delete', command: "wordpress-suite:site:user:delete:#{@namespace}:#{user.user_login}" })
						submenu.push({ type: 'separator' })
						submenu.push({ label: "ID: #{user.ID}", enabled: false })
						submenu.push({ label: "Email: #{user.user_email}", enabled: false })
						submenu.push({ label: "Name: #{user.display_name}", enabled: false })
						submenu.push({ label: "Roles: #{user.roles}", enabled: false })

						@menu.push({ label: user.user_login, submenu: submenu })

				@subscriptions.add atom.commands.add ".project-root", "wordpress-suite:site:users:disable:#{@namespace}": (event) => site = atom.wordpressSuite.getSelectedSite().wpcli.users.disable()
				@menu.push({ label: 'Disable', command: "wordpress-suite:site:users:disable:#{@namespace}" })
		else
			@subscriptions.add atom.commands.add ".project-root", "wordpress-suite:site:users:enable:#{@namespace}": (event) => site = atom.wordpressSuite.getSelectedSite().wpcli.users.enable()
			@menu.push({ label: 'Enable', command: "wordpress-suite:site:users:enable:#{@namespace}" })

		@subscriptions.add atom.contextMenu.add { ".project-root": [{ label: 'Wordpress Suite', submenu: [{ label: 'Users', submenu: [], created: (-> @submenu = atom.wordpressSuite.getSelectedSite().wpcli.users.getMenu()), shouldDisplay: (-> atom.wordpressSuite.getSelectedSite().wpcli.users)}] }] }

	getMenu: ->
		if @menu.length > 0
			return @menu
		return [{ label: "Loading...", enabled: false }]

	delete: (user_login) ->
		@emitter.emit 'notification', [ "Deleting #{user_login}", 'info' ]
		@wp.user.delete user_login, (err,message) =>
			if err
				@emitter.emit 'message', [ "Error Deleting #{user_login}", 'error', err ]
			else
				@emitter.emit 'message', [ "#{user_login} Deleted", 'success', message ]
				@refresh()

	onNotification: (callback) ->
		@emitter.on('notification', callback)

	onMessage: (callback) ->
		@emitter.on('message', callback)

	dispose: ->
		@log "Disposed", 6

		@subscriptions?.dispose()

		if atom.inDevMode()
			@logger = -> ->
			@log = ->
			@wp = null
			@subscriptions = null
			@emitter = null
			@directory = null
			@menu = []
			@enabled = null