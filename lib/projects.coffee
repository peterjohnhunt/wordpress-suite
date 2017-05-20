{CompositeDisposable, Disposable} = require 'atom'
Site = require './site'

Array.prototype.difference = (a) ->
	return @filter (i) ->
		return a.indexOf(i) < 0

module.exports = class Projects

	constructor: (logger) ->
		@logger = logger
		@log = @logger "projects"
		@sites = []
		@projectPaths = atom.project.getPaths()
		@subscriptions = new CompositeDisposable
		@subscriptions.add atom.project.onDidChangePaths (projectPaths) => @update(projectPaths)

		@add(@projectPaths)
		@log 'Created', 6

		new Disposable()

	getId: (sitePath) ->
		for site, index in @sites
			if site.containsPath(sitePath)
				return index
		return -1

	getSite: (sitePath) ->
		siteId = @getId(sitePath)
		if siteId > -1
			site = @sites[siteId]
			return site

	get: ->
		return @sites

	update: (projectPaths) ->
		if projectPaths.length > @projectPaths.length
			addedPaths = projectPaths.difference(@projectPaths);
			@add(addedPaths)
		else
			removedPaths = @projectPaths.difference(projectPaths);
			@remove(removedPaths)
		@projectPaths = projectPaths

		@log 'Updated', 6

	add: (projectPaths) ->
		for projectPath in projectPaths
			siteId = @getId(projectPath)
			if siteId > -1
				site = @sites[siteId]
				site.addPath(projectPath)
			else
				@subscriptions.add site = new Site(projectPath,@logger)
				length = @sites.push(site)
				siteId = length - 1

		@log 'Added', 6

	remove: (projectPaths) ->
		for projectPath in projectPaths
			siteId = @getId(projectPath)
			if siteId isnt false
				site = @sites[siteId]
				site.removePath(projectPath)
				if not site.hasPaths()
					site.dispose()
					@subscriptions.remove site
					@sites.splice(siteId,1);
		@log 'Removed', 6

	dispose: ->

		# Clean Up Subscriptions
		@subscriptions?.dispose()

		@log 'Deleted', 6

		if atom.inDevMode()
			@log = ->
			@log = -> ->
			@sites = []
			@projectPaths = null
			@view = null
			@subscriptions = null