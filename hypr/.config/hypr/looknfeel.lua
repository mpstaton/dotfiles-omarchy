-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- Size gaps as a share of each monitor instead of fixed pixels, so a small
-- laptop screen gets tight gaps and a big monitor gets roomier ones. The share
-- is measured against the monitor's short side in logical pixels (after
-- scaling), e.g. a 2560x1600 MacBook Air at scale 2 is 800 tall.
local gaps_in_percent = 0.25  -- between windows
local gaps_out_percent = 0.5  -- between windows and the screen edge

local function percent_of(monitor, percent)
  local short_side = math.min(monitor.width, monitor.height) / monitor.scale
  return math.floor(short_side * percent / 100 + 0.5)
end

local function fit_gaps()
  -- Leave Omarchy's no-gaps toggle in charge while it's on, since a workspace
  -- rule would otherwise override it.
  local state_home = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
  local no_gaps = io.open(state_home .. "/omarchy/toggles/hypr/window-no-gaps.lua", "r")
  if no_gaps then
    no_gaps:close()
    return
  end

  for _, monitor in ipairs(hl.get_monitors()) do
    -- A monitor that is going away answers nil, which layout changes can catch.
    if monitor.name and monitor.scale and monitor.scale > 0 then
      -- s[false] skips special workspaces so the scratchpad console, which is
      -- sized by its own gap rule, is left alone. Reusing the same selector
      -- replaces the rule in place rather than stacking a new one.
      hl.workspace_rule({
        workspace = "m[" .. monitor.name .. "]s[false]",
        gaps_in = percent_of(monitor, gaps_in_percent),
        gaps_out = percent_of(monitor, gaps_out_percent),
      })
    end
  end
end

fit_gaps()
hl.on("monitor.added", fit_gaps)
hl.on("monitor.layout_changed", fit_gaps)

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })
