# module.exports = class ProjectsView
#
# 	constructor: (logger) ->
# 		@logger = logger
# 		@log = @logger "projects.view"
#
# 		@element = document.createElement('div')
# 		@element.classList.add('wordpress-suite')
#
# 		title = document.createElement('h1')
# 		title.textContent = 'Wordpress Suite'
# 		title.classList.add('title')
#
# 		@element.appendChild(title)
#
# 		projects = document.createElement('ul')
# 		projects.classList.add('projects')
# 		@element.appendChild(projects)
# 		@log 'Created', 6
#
# 		# html = ''
# 		# for site in sites
# 		# 	html += "<li>#{site.name}</li>"
#
# 		# projects.innerHTML = html
#
# 	getTitle: ->
# 		return 'Wordpress Suite'
#
# 	getURI: ->
# 		return 'atom://wordpress-suite'
#
# 	getDefaultLocation: ->
# 		return 'right'
#
# 	getAllowedLocations: ->
# 		return ['left', 'right', 'bottom']
#
# 	serialize: ->
# 		return
#
# 	destory: ->
# 		@log 'Removed', 6
# 		return
#
# 	getElement: ->
# 		return @element
# @subscriptions.add atom.commands.add 'atom-workspace',
# 	"#{config.name}:projects:view:open": -> atom.workspace.open(config.uri)
#
# @subscriptions.add atom.workspace.addOpener (uri) =>
# 	if uri.startsWith(config.uri)
# 		if not @view? or @view.destroyed
# 			@view = new View(@logger)
# 		return @view
# @wp.plugin.list (err,plugins) =>
#     if not err
#         @plugins = plugins
#
#         menu = []
#         for plugin in @plugins
#
#             @subscriptions.add atom.commands.add ".project-root",
#                 "wordpress-suite:site:plugin:add-folder:#{plugin.name}": (event) =>
#                     name = event.type.split(':').pop()
#                     atom.project.addPath(@directory.getSubdirectory(name).getPath())
#                 "wordpress-suite:site:plugin:activate:#{plugin.name}": (event) =>
#                     name = event.type.split(':').pop()
#                     site = atom.wordpressSuite.getSelectedSite().wpcli.plugins.activate(name)
#                 "wordpress-suite:site:plugin:deactivate:#{plugin.name}": (event) =>
#                     name = event.type.split(':').pop()
#                     site = atom.wordpressSuite.getSelectedSite().wpcli.plugins.deactivate(name)
#                 "wordpress-suite:site:plugin:update:#{plugin.name}": (event) =>
#                     name = event.type.split(':').pop()
#                     site = atom.wordpressSuite.getSelectedSite().wpcli.plugins.update(name)
#                 "wordpress-suite:site:plugin:delete:#{plugin.name}": (event) =>
#                     name = event.type.split(':').pop()
#                     site = atom.wordpressSuite.getSelectedSite().wpcli.plugins.delete(name)
#
#             menu.push({ label: plugin.name, submenu: [
#                 { label: 'Add Folder', command: "wordpress-suite:site:plugin:add-folder:#{plugin.name}", shouldDisplay: ->
#                     name = @command.split(':').pop()
#                     site = atom.wordpressSuite.getSelectedSite()
#                     plugin = site.wpcli.plugins.directory.getSubdirectory(name)
#                     return not site.hasPath("#{plugin.getPath()}")
#                 }
#                 { label: 'Activate', command: "wordpress-suite:site:plugin:activate:#{plugin.name}", shouldDisplay: ->
#                     name = @command.split(':').pop()
#                     return atom.wordpressSuite.getSelectedSite().wpcli.plugins.get(name).status is 'inactive'
#                 }
#                 { label: 'Deactivate', command: "wordpress-suite:site:plugin:deactivate:#{plugin.name}", shouldDisplay: ->
#                     name = @command.split(':').pop()
#                     return atom.wordpressSuite.getSelectedSite().wpcli.plugins.get(name).status is 'active'
#                 }
#                 { label: 'Update', command: "wordpress-suite:site:plugin:update:#{plugin.name}", shouldDisplay: ->
#                     name = @command.split(':').pop()
#                     return atom.wordpressSuite.getSelectedSite().wpcli.plugins.get(name).update is 'available'
#                 }
#                 { label: 'Delete', command: "wordpress-suite:site:plugin:delete:#{plugin.name}" }
#                 { type: 'separator' }
#                 { label: "Version: #{plugin.version}", enabled: false }
#                 { label: "Status: #{plugin.status}", enabled: false }
#                 { label: "Update: #{plugin.update}", enabled: false }
#             ], shouldDisplay: -> atom.wordpressSuite.getSelectedSite().wpcli.plugins.get(@label) })
#
#         @subscriptions.add atom.contextMenu.add { ".project-root": [{ label: 'Wordpress Suite', submenu: [{ label: 'Plugins', submenu: menu, shouldDisplay: -> atom.wordpressSuite.getSelectedSite().wpcli.hasPlugins() }] }] }