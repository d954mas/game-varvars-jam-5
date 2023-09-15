local COMMON = require "libs.common"
local WORLD = require "world.world"
local DEFS = require "world.balance.def.defs"
local GOOEY = require "gooey.gooey"
local Button1 = require "libs_project.gui.button_1"

local COLORS = COMMON.CONSTANTS.COLORS

local View = COMMON.class("UpgradeItemView")

function View:initialize(list_data, name)
	self.list_data = assert(list_data)
	--filter some upgrades. Add them later
	self:list_prepare(assert(name))
end

function View:list_update_item(list, item)
	if (item.data and item.data ~= "") then
		if not item.my_views then
			item.my_views = {
				cat_1 = {},
				cat_2 = {},
			}
		end
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