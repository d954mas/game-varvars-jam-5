local COMMON = require "libs.common"
local WORLD = require "world.world"
local DEFS = require "world.balance.def.defs"
local GOOEY = require "gooey.gooey"
local GUI = require "libs_project.gui.gui"
local Button1 = require "libs_project.gui.button_1"

local COLORS = COMMON.CONSTANTS.COLORS

local CatItem = COMMON.class("CatItem")

function CatItem:initialize(nodes)
	self.vh = {
		root = assert(nodes.root),
		icon = assert(nodes.icon),
		lbl_title = assert(nodes.lbl_title),
		lbl_description = assert(nodes.lbl_description),
		notification = assert(nodes.notification)
	}
end

function CatItem:set_enabled(enabled)
	gui.set_enabled(self.vh.root, enabled)
end

function CatItem:set_cat(id)
	self.id = assert(id)
	self.def = assert(DEFS.CATS.CATS[id])
	self:update_view()

end

function CatItem:update_view()
	gui.play_flipbook(self.vh.icon, self.def.sprite)
	local name = COMMON.LOCALIZATION["cat_" .. self.def.id .. "_name"]()
	local description = COMMON.LOCALIZATION["cat_" .. self.def.id .. "_description"]()
	if (WORLD.storage.cats:is_collected(self.def.id)) then
		gui.reset_material(self.vh.icon)
		gui.set_color(self.vh.icon, COLORS.CAT_SHOW)
	else
		gui.set_material(self.vh.icon, "gui_grayscale")
		gui.set_color(self.vh.icon, COLORS.CAT_HIDDEN)
		name = "????"
		description = "???????\n???????\n???????"
	end

	local need_notification = WORLD.storage.cats:is_collected(self.def.id) and
			not WORLD.storage.cats:is_look_at_book(self.def.id)
	gui.set_enabled(self.vh.notification, need_notification)

	GUI.autosize_text(self.vh.lbl_title, 0.75, name)

	gui.set_text(self.vh.lbl_description, description)
end

local View = COMMON.class("UpgradeItemView")

function View:initialize(list_data, name)
	self.list_data = assert(list_data)
	--filter some upgrades. Add them later
	self:list_prepare(assert(name))
end

function View:list_update_item(list, item)
	if (item.data and item.data ~= "") then
		if not item.my_views then
			local cats = {}
			for i = 1, 2 do
				local id = list.id .. "/item/item_" .. i
				local vh = {
					root = assert(item.nodes[hash(id .. "/root")]),
					icon = assert(item.nodes[hash(id .. "/icon")]),
					lbl_title = assert(item.nodes[hash(id .. "/lbl_title")]),
					lbl_description = assert(item.nodes[hash(id .. "/lbl_description")]),
					notification = assert(item.nodes[hash(id .. "/icon_attention")]),
				}
				table.insert(cats, CatItem(vh))
			end

			item.my_views = {
				cats = cats
			}
		end
		local cat_1 = item.data.cat_1.def
		local cat_2 = item.data.cat_2.def
		item.my_views.cats[1]:set_enabled(cat_1)
		item.my_views.cats[2]:set_enabled(cat_2)
		if (cat_1) then item.my_views.cats[1]:set_cat(cat_1.id) end
		if (cat_2) then item.my_views.cats[2]:set_cat(cat_2.id) end
	end
end

function View:list_prepare(name)
	self.listitem_refresh = function(list)
		for _, item in ipairs(list.items) do
			self:list_update_item(list, item)
		end
	end
	self.listitem_clicked = function(list) end

	self.cats_list = GOOEY.dynamic_list(name, name .. "/stencil",
			name .. "/item/root", self.list_data, nil, nil, nil,
			self.listitem_clicked, self.listitem_refresh)

end

function View:refresh()
	self.listitem_refresh(self.cats_list)
	GOOEY.dynamic_list(self.cats_list.id, self.cats_list.stencil_id, self.cats_list.item_id,
			self.cats_list.data, nil, nil, nil, self.listitem_clicked, self.listitem_refresh)
end

function View:update(dt)

end

function View:on_input(action_id, action)
	if (not self.cats_list.have_scrolled) then

	end

	GOOEY.dynamic_list(self.cats_list.id, self.cats_list.stencil_id, self.cats_list.item_id,
			self.cats_list.data, action_id, action, nil, self.listitem_clicked, self.listitem_refresh)



	--fixed have_scrolled update
	if (action.released) then
		GOOEY.dynamic_list(self.cats_list.id, self.cats_list.stencil_id, self.cats_list.item_id,
				self.cats_list.data, action_id, action, nil, self.listitem_clicked, self.listitem_refresh)
		self.cats_list.have_scrolled = false
	end

	if (self.cats_list.consumed) then return true end

end

return View