
class Pool
	new_object: =>

	obtain: =>
		if item = table.remove(@items, 1)
			return item
		return @new_object!


	free: (item) =>
		table.insert(@items, item)

class HTMLCompPool extends Pool
	new_object: =>
		comp = vgui.Create("DHTML")
		with comp
			\SetPaintedManually true
		comp

html_pool = HTMLCompPool()

class WebMediaType extends wyozimc.BaseMediaType
	create: =>
		@html = html_pool\obtain!
		
	destroy: =>
		html_pool\free(@html)

wyozimc.AddMediaType("web", WebMediaType)