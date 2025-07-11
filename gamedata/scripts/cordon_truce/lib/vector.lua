local UTIL  = require "cordon_truce.lib.util"
local TABLE = require "cordon_truce.lib.table"


local VEC = {}

VEC.INVALID_LVID = 4294967295


function VEC.set(...)
  return vector():set(...)
end


function VEC.direction(a, b)
  return VEC.set(b):sub(a):normalize()
end


function VEC.distance(a, b)
  return a:distance_to(b)
end


function VEC.offset(point, dir, dist)
  return VEC.set(point):add(
    VEC.set(dir):normalize():mul(dist)
  )
end


function VEC.rotate(point, angle)
  return vector_rotate_y(point, angle)
end


function VEC.rotateRange(point, angle, prec, weight)
  angle = angle or 180
  return VEC.rotateRandom(point, -angle, angle, prec, weight)
end


function VEC.dotProduct(a, b)
  return VEC.set(a):dotproduct(b)
end


function VEC.lvid(pos)
  return level.vertex_id(pos) or 4294967295
end


function VEC.position(vid)
  return VEC.set(level.vertex_position(vid))
end


function VEC.claimLVID(npc, vid)
  VEC.unclaimLVID(npc)
  db.used_level_vertex_ids[vid] = npc:id()
end


function VEC.unclaimLVID(npc, vid)
  local used = db.used_level_vertex_ids

  if vid and used[vid] == npc:id() then
    used[vid] = nil
    return
  end

  for v, id in pairs(used) do
    if id == npc:id() then
      used[v] = nil
    end
  end
end


function VEC.setLVID(npc, vid)
  VEC.clearLVID(npc)
  VEC.claimLVID(npc, vid)
  npc:set_dest_level_vertex_id(vid)
end


function VEC.clearLVID(npc)
  VEC.unclaimLVID(npc)
  npc:set_desired_position()
  npc:set_desired_direction()
  npc:set_path_type(game_object.level_path)
  npc:set_detail_path_type(move.line)
end


function VEC.isValidLVID(npc, vid)
  return npc and vid
    and vid ~= VEC.INVALID_LVID
    and npc:accessible(vid)
end


function VEC.isUnclaimedLVID(npc, vid, space)
  space = space or 0.4

  if not VEC.isValidLVID(npc, vid) then
    return false
  end

  if space > 0 then
    for v, id in pairs(db.used_level_vertex_ids) do
      if id ~= npc:id() then
        if v == vid or VEC.distance(VEC.position(v), VEC.position(vid)) < space then
          return false
        end
      end
    end
  end

  return true
end


function VEC.isUnoccupiedLVID(npc, vid, space)
  local space = space or 0.8

  if not VEC.isUnclaimedLVID(npc, vid, space) then
    return false
  end

  local pos = VEC.position(vid)
  local unoccupied = true

  level.iterate_nearest(pos, space + 0.1, function(obj)
    if not IsStalker(obj) or obj:id() == npc:id() then
      return
    end

    local objPos = obj:position()
    local used = TABLE.keyof(db.used_level_vertex_ids, obj:id())

    if used and used ~= vid then
      objPos = VEC.position(used)
    end

    if VEC.distance(pos, objPos) < space then
      unoccupied = false
      return true
    end
  end)

  return unoccupied
end


function VEC.legacyLVID(npc, fromPos, pos, validator, spacing)
  spacing = spacing or 1

  local dist = VEC.distance(fromPos, pos)
  local dir  = VEC.direction(fromPos, pos)

  while dist > 0 do
    local vid = level.vertex_in_direction(VEC.lvid(fromPos), dir, dist)

    if validator(npc, vid, spacing) then
      return vid
    end

    dist = dist - spacing
  end

  return VEC.INVALID_LVID
end


function VEC.legacyValidLVID(npc, fromPos, pos, spacing)
  return VEC.legacyLVID(npc, fromPos, pos, VEC.isValidLVID, spacing)
end


function VEC.legacyUnclaimedLVID(npc, fromPos, pos, spacing)
  return VEC.legacyLVID(npc, fromPos, pos, VEC.isUnclaimedLVID, spacing)
end


function VEC.legacyUnoccupiedLVID(npc, fromPos, pos, spacing)
  return VEC.legacyLVID(npc, fromPos, pos, VEC.isUnoccupiedLVID, spacing)
end


function VEC.getStrafePos(npc, options)
  options = TABLE.merge({
    findFn   = VEC.legacyUnclaimedLVID,
    enemyPos = db.actor:position(),
    findFrom = npc:position(),
    range    = 10,
    distance = 8,
    spacing  = 1,
  }, options)

  local enemyDir = VEC.direction(options.findFrom, options.enemyPos)

  local dir1   = vec_rot(enemyDir, -90 + UTIL.randomRange(10))
  local dir2   = vec_rot(enemyDir,  90 + UTIL.randomRange(10))
  local pos1   = vec_offset(options.findFrom, dir1, options.distance)
  local pos2   = vec_offset(options.findFrom, dir2, options.distance)
  local vid1   = options.findFn(npc, options.findFrom, pos1, options.spacing)
  local vid2   = options.findFn(npc, options.findFrom, pos2, options.spacing)
  local valid1 = VEC.isValidLVID(npc, vid1)
  local valid2 = VEC.isValidLVID(npc, vid2)

  if not (valid1 or valid2) then
    return VEC.INVALID_LVID
  end

  if not (valid1 and valid2) then
    return valid1 and vid1 or vid2
  end

  return vec_dist(options.findFrom, lvpos(vid2)) > vec_dist(options.findFrom, lvpos(vid1))
    and vid2
    or  vid1
end


return VEC
