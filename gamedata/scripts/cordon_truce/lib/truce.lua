local UTIL  = require "cordon_truce.lib.util"
local TABLE = require "cordon_truce.lib.table"
local VEC   = require "cordon_truce.lib.vector"
local NPC   = require "cordon_truce.lib.npc"

local TRUCE = {}

TRUCE.LEVELS      = {"l01_escape"}
TRUCE.COMMUNITIES = {"bandit", "stalker"}
TRUCE.SUSPENDED   = nil

TRUCE.CONFIG = {
  companionsWarn   = false,
  tooCloseSuspends = false,
  warnDist         = 16,
  attackDist       = 8,
  warnTime         = 60000,
  retreatTime      = 30000,
  ignoreTime       = 180000,
  suspendTime      = 6 * 3600000,
}


function TRUCE.participant(npc)
  local npc  = NPC.get(npc)
  local comm = NPC.community(npc)

  return npc and comm
    and TABLE.keyof(TRUCE.COMMUNITIES, comm)
    and TABLE.keyof(TRUCE.LEVELS, level.name())
end


function TRUCE.between(npc, enemy)
  local npc   = NPC.get(npc)
  local enemy = NPC.get(enemy)

  return npc and enemy
    and npc:alive() and enemy:alive()
    and TRUCE.participant(npc)
    and TRUCE.participant(enemy)
    and NPC.community(npc) ~= NPC.community(enemy)
end


function TRUCE.onUpdateNPC(npc)
  local npc = NPC.get(npc)
  local st  = NPC.storage(npc, "cordon_truce")

  if not TRUCE.participant(npc) or TRUCE.SUSPENDED then
    return
  end

  local stalkers = TABLE.imerge(db.OnlineStalkers, {0})

  TABLE.ipairscb(stalkers, function(id)
    local enemy = NPC.get(id)
    if not enemy or not enemy:alive() then
      return
    end

    local ncomm = NPC.community(npc)
    local ecomm = nil
      or ncomm == TRUCE.COMMUNITIES[1] and TRUCE.COMMUNITIES[2]
      or ncomm == TRUCE.COMMUNITIES[2] and TRUCE.COMMUNITIES[1]

    if NPC.community(enemy) ~= ecomm then
      return
    end

    local dist = VEC.distance(npc:position(), enemy:position())
    if not st.dist or dist < st.dist then
      st.closest = id
      st.dist  = dist
    end
  end)
end


function TRUCE.onUpdateSquad(squad)
  if not squad.online or TRUCE.SUSPENDED then
    return
  end

  local ncomm = NPC.community(squad)
  local ecomm = false
    or ncomm == TRUCE.COMMUNITIES[1] and TRUCE.COMMUNITIES[2]
    or ncomm == TRUCE.COMMUNITIES[2] and TRUCE.COMMUNITIES[1]

  if not ecomm then
    return
  end

  local order = {warn = 1, retreat = 2, ignore = 3, attack = 4}
  local status

  for member in squad:squad_members() do
    local npc = NPC.get(member.id)
    local st  = NPC.storage(member.id, "cordon_truce")

    status = (order[status] or 0) <= (order[st.action] or 0)
      and st.action
      or  status
  end

  for member in squad:squad_members() do
    local st = NPC.storage(member.id, "cordon_truce")
    st.status = status
    st.squad  = true
  end
end


function TRUCE.onUpdateTruce(npc, amount, dir, who, bone)
  if not TRUCE.between(npc, who) then
    return
  end

  if TRUCE.CONFIG.suspendTime == 0 then
    return
  end

  local suspend = false

  if who:id() == 0 then
    suspend = true
  end

  local nst = NPC.storage(npc, "cordon_truce")
  local wst = NPC.storage(who, "cordon_truce")

  if TRUCE.CONFIG.tooCloseSuspends then
    suspend = true
  end

  if nst.action ~= "attack" and wst.action ~= "attack" then
    suspend = true
  end

  if not suspend then
    return
  end

  if not TRUCE.SUSPENDED then
    SendScriptCallback("on_cordon_truce_suspend", who, npc)
  end

  TRUCE.SUSPENDED = {
    time = UTIL.gtimePlus(TRUCE.CONFIG.suspendTime),
    id   = who:id()
  }
end


function TRUCE.onUpdateEnemy(npc, enemy, flags)
  if not TRUCE.between(npc, enemy) or TRUCE.SUSPENDED then
    return
  end

  local nst = NPC.storage(npc, "cordon_truce")
  local est = NPC.storage(enemy, "cordon_truce")

  if nst.status ~= "attack" and est.status ~= "attack" then
    flags.result   = false
    flags.override = true
  end
end


function TRUCE.onSuspend(who)
  UTIL.sendNews("msg_cordon_truce_suspended",
    who:character_name(),
    NPC.community(who)
  )
end


function TRUCE.onResume()
  UTIL.sendNews("msg_cordon_truce_resumed")
end


function TRUCE.onCheckTruceKey(dik)
  local key  = ui_mcm.get("cordon_truce/key")
  local mkey = ui_mcm.get("cordon_truce/mod")
  local mod  = ui_mcm.get_mod_key(mkey)

  if not (key and key > 0 and key == dik and mod) then
    return
  end

  if not TRUCE.SUSPENDED then
    UTIL.sendNews("msg_cordon_check_truce_active")
    return
  end

  local secs  = UTIL.round((TRUCE.SUSPENDED.time - game.time()) / 1000)
  local mins  = UTIL.round(secs / 60)
  local hours = UTIL.round(mins / 60)

  if secs < 1 then
    UTIL.sendNews("msg_cordon_check_truce_active")
    return
  end

  local time, unit

  if hours > 0 then
    unit = "msg_cordon_check_truce_hours"
    time = hours
  elseif mins > 0 then
    unit = "msg_cordon_check_truce_mins"
    time = mins
  else
    unit = "msg_cordon_check_truce_secs"
    time = secs
  end

  UTIL.sendNews("msg_cordon_check_truce_suspended", time, game.translate_string(unit))
end


function TRUCE.onCheckTruceTime()
  if TRUCE.SUSPENDED and UTIL.gtimeExpired(TRUCE.SUSPENDED.time) then
    TRUCE.SUSPENDED = nil
    SendScriptCallback("on_cordon_truce_resume")
  end
end


function TRUCE.onConfigure()
  if ui_mcm then
    TRUCE.CONFIG = TABLE.merge(TRUCE.CONFIG, {
      companionsWarn   = ui_mcm.get("cordon_truce/companionsWarn"),
      tooCloseSuspends = ui_mcm.get("cordon_truce/tooCloseSuspends"),
      warnDist         = ui_mcm.get("cordon_truce/warnDist"),
      attackDist       = ui_mcm.get("cordon_truce/attackDist"),
      suspendTime      = ui_mcm.get("cordon_truce/suspendTime") * 1000,
      warnTime         = ui_mcm.get("cordon_truce/warnTime")    * 1000,
      ignoreTime       = ui_mcm.get("cordon_truce/ignoreTime")  * 1000,
    })
  end
end


function TRUCE.onSaveState(mdata)
  if not mdata.CORDON_TRUCE then
    mdata.CORDON_TRUCE = {}
  end
  mdata.CORDON_TRUCE.suspended = TRUCE.SUSPENDED
end


function TRUCE.onLoadState(mdata)
  if mdata.CORDON_TRUCE then
    TRUCE.SUSPENDED = mdata.CORDON_TRUCE.suspended
  end
end


AddScriptCallback("on_cordon_truce_suspend")
AddScriptCallback("on_cordon_truce_resume")


return TRUCE
