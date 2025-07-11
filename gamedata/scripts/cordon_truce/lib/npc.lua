local NPC = {}


function NPC.storage(id, key)
  if type(id) == "userdata" then
    id = id:id()
  end

  return db.storage[id] and key
    and db.storage[id][key]
    or  db.storage[id]
end


function NPC.get(id)
  return NPC.storage(id, "object")
end


function NPC.isCompanion(npc)
  if type(npc) == "number" then
    npc = NPC.get(npc)
  end

  return npc
    and not axr_task_manager.hostages_by_id[npc:id()]
    and npc:has_info("npcx_is_companion")
    and npc:alive()
    and true
    or false
end


function NPC.community(thing)
  if type(thing) == "userdata" and thing.squad_members then
    return thing:get_squad_community()
  end

  return character_community(NPC.get(thing)):gsub("^actor_", "")
end


return NPC
