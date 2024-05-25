require("spinner")
local channel = love.thread.getChannel("installPipe")

local thread_manager = {
    thread_instance = nil,

    start = function(self)
        self.thread_instance = love.thread.newThread("install_thread.lua")
        self.thread_instance:start()
    end,

    run = function(self)
        local channel_message = channel:pop()
        if(channel_message) then
            self.thread_messages[channel_message[1]](self, unpack(channel_message))
        end
    end,

    thread_messages = {
        ["SetTitleAndSubtitle"] = function(self, name, title, subtitle)
            Spinner.ui.title = title
            Spinner.ui.subtitle = subtitle
        end,

        ["SetAnimation"] = function(self, name, animation)
           Spinner.animState = SpinnerAnimations[animation] 
        end
    }
}

function love.load(args)
    thread_manager:start()
end

function love.draw()
    Spinner:draw(85, 85)
    thread_manager:run()
end