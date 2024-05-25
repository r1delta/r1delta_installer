math["map"] = function(x, in_min, in_max, out_min, out_max) 
    return ((x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min)
end

local font = love.graphics.newFont(11, "mono")
love.graphics.setFont(font)

SpinnerAnimations = {
    ["ERROR"] = 1,
    ["IDLE"] = 2,
    ["WORKING"] = 4,
}

Spinner = {
    frameCount = 0,

    radClosest = 50,
    radFurthest = 70,

    animState = SpinnerAnimations.WORKING,

    ui = {
        title = "R1Delta installer",
        subtitle = "Initializing..."
    },

    colorFunc = {
        [SpinnerAnimations.IDLE] = function(sStart, sEnd, idx)
            love.graphics.setColor(0.6, 0.6, 0.6)
        end,

        [SpinnerAnimations.WORKING] = function(sStart, sEnd, idx)
            love.graphics.setColor(0.12, 0.12, 0.12)
            if(idx > sStart) then idx = idx - 30 end
            if(sStart >= idx and idx >= sEnd) then
                local col = math.map(idx, sEnd, sStart, 0.12, 0.6)
                love.graphics.setColor(col, col, col)
            end
        end,

        [SpinnerAnimations.ERROR] = function(sStart, sEnd, idx)
            love.graphics.setColor(0.12, 0, 0)
            if(idx > sStart) then idx = idx - 30 end
            if(sStart >= idx and idx >= sEnd) then
                local col = math.map(idx, sEnd, sStart, 0.6, 0.12)
                love.graphics.setColor(col, 0, 0)
            end
        end,
    },

    draw = function(self, x, y)
        love.graphics.push()
        love.graphics.translate(x, y)

        local spinnerFadeStart = math.floor((self.frameCount / self.animState) % 30)
        if(self.animState == SpinnerAnimations.ERROR) then spinnerFadeStart = 30 - spinnerFadeStart end
        local spinnerFadeEnd = spinnerFadeStart - 15

        for i = 0,29,1 do
            local ang_l = ((360 / 30) * i - 4 + 15) * 0.0174533
            local ang_r = ((360 / 30) * i + 4 + 15) * 0.0174533

            local verts = {
                math.cos(ang_l) * self.radClosest,
                math.sin(ang_l) * self.radClosest,
                math.cos(ang_l) * self.radFurthest,
                math.sin(ang_l) * self.radFurthest,
                math.cos(ang_r) * self.radFurthest,
                math.sin(ang_r) * self.radFurthest,
                math.cos(ang_r) * self.radClosest,
                math.sin(ang_r) * self.radClosest
            }

            self.colorFunc[self.animState](spinnerFadeStart, spinnerFadeEnd, i)
            love.graphics.polygon("fill", verts)
        end

        self.frameCount = self.frameCount + 1 * love.timer.getDelta() * 63
        love.graphics.pop()

        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(self.ui.title, 200, 50)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print(self.ui.subtitle, 200, 75)
    end
}