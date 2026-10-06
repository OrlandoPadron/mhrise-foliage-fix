-- foliage_fix.lua
-- Fixes grass flickering in MH Rise by lowering the alpha-test cutoff
-- (AlphaTest_Param) of the materials: with the game's value (0.5) thin grass
-- blades pop in and out as the texture mipmap changes with distance.
-- Adjustable in REFramework: Insert -> Script Generated UI -> Foliage Fix.

local CONFIG_FILE = "foliage_fix.json"
local PARAM_NAME = "AlphaTest_Param"
local SCAN_INTERVAL_SEC = 2

local cfg = json.load_file(CONFIG_FILE) or {}
if cfg.enabled == nil then cfg.enabled = true end
if type(cfg.alpha_test) ~= "number" then cfg.alpha_test = 0.25 end

local scene_manager_td = sdk.find_type_definition("via.SceneManager")

-- mesh address -> list of { mi, vi, original } holding the parameter (empty if it has none)
local targets_by_mesh = {}
local stats = { meshes = 0 }
local last_error = ""
local last_scan = -SCAN_INTERVAL_SEC

local function current_meshes()
    local sm = sdk.get_native_singleton("via.SceneManager")
    if not sm then return {} end
    local scene = sdk.call_native_func(sm, scene_manager_td, "get_CurrentScene")
    if not scene then return {} end
    local arr = scene:call("findComponents(System.Type)", sdk.typeof("via.render.Mesh"))
    return arr and arr:get_elements() or {}
end

local function collect_targets(mesh)
    local list = {}
    for mi = 0, mesh:call("get_MaterialNum") - 1 do
        for vi = 0, mesh:call("getMaterialVariableNum", mi) - 1 do
            if mesh:call("getMaterialVariableName", mi, vi) == PARAM_NAME then
                list[#list + 1] = { mi = mi, vi = vi, original = mesh:call("getMaterialFloat", mi, vi) }
            end
        end
    end
    return list
end

local function apply_to_mesh(mesh, targets)
    for _, t in ipairs(targets) do
        mesh:call("setMaterialFloat", t.mi, t.vi, cfg.enabled and cfg.alpha_test or t.original)
    end
end

-- reapply_all: rewrite every mesh (after a setting change); otherwise only new ones.
local function update(reapply_all)
    if not cfg.enabled and not reapply_all then return end
    local present = {}
    local count = 0
    for _, mesh in ipairs(current_meshes()) do
        pcall(function()
            local addr = mesh:get_address()
            present[addr] = true
            local targets = targets_by_mesh[addr]
            local is_new = targets == nil
            if is_new then
                targets = collect_targets(mesh)
                targets_by_mesh[addr] = targets
            end
            if #targets > 0 then
                count = count + 1
                if is_new or reapply_all then apply_to_mesh(mesh, targets) end
            end
        end)
    end
    -- Forget unloaded meshes: their address may be reused by a new one.
    for addr in pairs(targets_by_mesh) do
        if not present[addr] then targets_by_mesh[addr] = nil end
    end
    stats.meshes = count
end

re.on_frame(function()
    local now = os.time()
    if now - last_scan < SCAN_INTERVAL_SEC then return end
    last_scan = now
    local ok, err = pcall(update, false)
    if not ok then last_error = tostring(err) end
end)

re.on_draw_ui(function()
    if not imgui.tree_node("Foliage Fix") then return end
    local c1, c2
    c1, cfg.enabled = imgui.checkbox("Enabled", cfg.enabled)
    c2, cfg.alpha_test = imgui.slider_float("Alpha-test cutoff (game default 0.5)", cfg.alpha_test, 0.0, 1.0)
    imgui.text("Affected meshes: " .. stats.meshes)
    if last_error ~= "" then imgui.text("Error: " .. last_error) end
    if c1 or c2 then
        json.dump_file(CONFIG_FILE, cfg)
        local ok, err = pcall(update, true)
        if not ok then last_error = tostring(err) end
    end
    imgui.tree_pop()
end)
