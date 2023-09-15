local COMMON = require "libs.common"
local POINTER = require "libs.pointer_lock"
local SM_ENUMS = require "libs.sm.enums"


local BaseScene = require "libs.sm.scene"
---@class UpgradesScene:Scene
local Scene = BaseScene:subclass("BookScene")
function Scene:initialize()
	BaseScene.initialize(self, "BookScene", "/book_scene#collectionproxy")
	self._config.modal = true
end

function Scene:update(dt)
	BaseScene.update(self, dt)
end

function Scene:resume()
	BaseScene.resume(self)
end

function Scene:pause()
	BaseScene.pause(self)
end

function Scene:pause_done()

end

function Scene:resume_done()

end

function Scene:show_done()
	POINTER.unlock_cursor()
end

function Scene:transition(transition)
	if (transition == SM_ENUMS.TRANSITIONS.ON_HIDE or
			transition == SM_ENUMS.TRANSITIONS.ON_BACK_HIDE) then
		local ctx = COMMON.CONTEXT:set_context_top_book_gui()
		ctx.data:animate_hide()
		ctx:remove()

		COMMON.coroutine_wait(0.2)
	elseif (transition == SM_ENUMS.TRANSITIONS.ON_SHOW) then
		local ctx = COMMON.CONTEXT:set_context_top_book_gui()
		ctx.data:animate_show()
		ctx:remove()
		COMMON.coroutine_wait(0.15)
	end
end

return Scene