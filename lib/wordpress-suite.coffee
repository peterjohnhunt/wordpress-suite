Wordpress = require './wordpress'
config = require './config'
{CompositeDisposable, Directory, File} = require 'atom'

Array.prototype.difference = (a) ->
	return @filter (i) ->
		return a.indexOf(i) < 0

module.exports = wordpressSuite =

	config: config

	consumeAutoreload: (reloader) ->
		reloader(pkg:"wordpress-suite",files:["package.json"],folders:["lib/","menus/","node_modules/"])

	activate: ->
		if atom.inDevMode()
			try
				@initialize()
			catch e
				console.log e
		else
			@initialize()

	initialize: ->
		# Variables
		@sites = [];
		@projectPaths = atom.project.getPaths();

		# Subscriptions
		@subscriptions = new CompositeDisposable
		@subscriptions.add atom.project.onDidChangePaths (projectPaths) => @foldersChanged(projectPaths)

		# Initial Setup
		@foldersAdded(@projectPaths)

	folderGetProjectId: (projectPath) ->
		for site, index in @sites
			if site.isRelatedPath(projectPath)
				return index
		return false

	foldersChanged: (projectPaths) ->
		if projectPaths.length > @projectPaths.length
			addedPaths = projectPaths.difference(@projectPaths);
			@foldersAdded(addedPaths)
		else
			removedPaths = @projectPaths.difference(projectPaths);
			@foldersRemoved(removedPaths)
		@projectPaths = projectPaths

	foldersAdded: (projectPaths) ->
		for projectPath in projectPaths
			site_id = @folderGetProjectId(projectPath)
			if site_id is false
				root = new Directory(projectPath.split('wp-content', 1)[0])
				if root.getSubdirectory('wp-content').existsSync()
					site = new Wordpress(root)
					site.addRelatedPath(projectPath)
					@sites.push(site)
			else
				site = @sites[site_id]
				site.addRelatedPath(projectPath)

	foldersRemoved: (projectPaths) ->
		for projectPath in projectPaths
			site_id = @folderGetProjectId(projectPath)
			if site_id isnt false
				site = @sites[site_id]
				site.removeRelatedPath(projectPath)
				if site.sitePaths.length is 0
					@sites[site_id].dispose()
					@sites.splice(site_id,1);

	deactivate: ->
		# Remove All Projects
		for site in @sites
			site.dispose()

		# Clean Up Subscriptions
		@subscriptions?.dispose()