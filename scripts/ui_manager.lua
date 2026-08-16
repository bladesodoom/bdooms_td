-- UI Manager
-- A vertical panel showing wave, countdown, and Core HP as text only.

local UiManager = {}

local FRAME_NAME = "td-overhaul-panel"
local OLD_LABEL_NAME = "td-overhaul-status"

local function get_or_create_panel(player)
    if player.gui.top[OLD_LABEL_NAME] then
        player.gui.top[OLD_LABEL_NAME].destroy()
    end

    local left = player.gui.left
    local frame = left[FRAME_NAME]
    if frame then return frame end

    frame = left.add {
        type = "frame",
        name = FRAME_NAME,
        direction = "vertical",
        caption = "Tower Defense",
    }

    local inner = frame.add {
        type = "table",
        name = "inner",
        column_count = 1,
    }

    inner.add { type = "label", name = "wave_label" }
    inner.add { type = "label", name = "timer_label" }
    inner.add { type = "label", name = "hp_label" }

    return frame
end

local function format_time(ticks)
    local total_seconds = math.max(0, math.ceil((ticks or 0) / 60))
    local minutes = math.floor(total_seconds / 60)
    local seconds = total_seconds % 60
    return string.format("%d:%02d", minutes, seconds)
end

function UiManager.update()
    local wave = storage.wave or 0
    local timer_text = format_time(storage.wave_timer)

    local hp_text = "—"
    if storage.core and storage.core.valid then
        hp_text = math.floor(storage.core.health) .. " / " .. math.floor(
            storage.core.max_health)
    end

    for _, player in pairs(game.players) do
        local frame               = get_or_create_panel(player)
        local inner               = frame.inner
        inner.wave_label.caption  = "Wave:       " .. wave
        inner.timer_label.caption = "Next wave: " .. timer_text
        inner.hp_label.caption    = "Core HP:   " .. hp_text
    end
end

function UiManager.on_player_joined(event)
    local player = game.players[event.player_index]
    if not player then return end
    get_or_create_panel(player)
    UiManager.update()
end

return UiManager
