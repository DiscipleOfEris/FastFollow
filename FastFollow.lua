_addon.name = 'FastFollow'
_addon.author = 'DiscipleOfEris'
_addon.version = '1.0.0'
_addon.commands = {'fastfollow', 'ffo'}

require('strings')
require('tables')
require('sets')
require('coroutine')
packets = require('packets')
res = require('resources')
spells = res.spells
items = res.items

follow_me = 0
following = false
target = nil
last_target = nil
min_dist = 0.20^2
max_dist = 50.0^2
repeated = false
last_self = nil
zone_walk_duration = 0.2
zone_walk_end = 0
zoned = false
casting = nil
pause_delay = 0.1
pause_dismount_delay = 0.5
pauseon = S{'spell','item','dismount'}
co = nil

windower.register_event('addon command', function(command, ...)
  command = command:lower()
  args = T{...}
  
  if not command then
    windower.add_to_chat(0, 'FastFollow: Provide a name to follow, or "me" to make others follow you.')
    windower.add_to_chat(0, 'FastFollow: Stop following with "stop" on a single character, or "stopall" on all characters.')
    windower.add_to_chat(0, 'FastFollow: Can configure auto-pausing with pauseon|pausedelay commands.')
  elseif command == 'followme' or command == 'me' then
    self = windower.ffxi.get_mob_by_target('me')
    if not self and not repeated then
      repeated = true
      windower.send_command('@wait 1; ffo followme')
      return
    end
    
    repeated = false
    windower.send_ipc_message('follow '..self.name)
  elseif command == 'stop' then
    follow_me = 0
    following = false
  elseif command == 'stopall' then
    follow_me = 0
    following = false
    windower.send_ipc_message('stop')
  elseif command == 'follow' then
    if #args == 0 then
      return windower.add_to_chat(0, 'FastFollow: You must provide a player name to follow.')
    end
    casting = nil
    following = args[1]:lower()
    windower.send_ipc_message('following '..following)
  elseif command == 'pauseon' then
    if #args == 0 then
      return windower.add_to_chat(0, 'FastFollow: To change pausing behavior, provide spell|item|any to pauseon.')
    end
    
    local arg = args[1]:lower()
    if arg == 'spell' or arg == 'any' then
      if pauseon:contains('spell') then pauseon:remove('spell')
      else pauseon:add('spell') end
    end
    if arg == 'item' or arg == 'any' then
      if pauseon:contains('item') then pauseon:remove('item')
      else pauseon:add('item') end
    end
    if arg == 'dismount' or arg == 'any' then
      if pauseon:contains('dismount') then pauseon:remove('dismount')
      else pauseon:add('dismount') end
    end
    
    windower.add_to_chat(0, 'FastFollow: Pausing on Spell: '..tostring(pauseon:contains('spell'))..', Item: '..tostring(pauseon:contains('item')))
    -- TODO: Save settings.
  elseif command == 'pausedelay' then
    pause_delay = tonumber(args[1])
    windower.add_to_chat(0, 'FastFollow: Setting item/spell pause delay to '..tostring(pause_delay)..' seconds.')
  elseif command then
    windower.send_command('ffo follow '..command)
  end
end)

windower.register_event('ipc message', function(msgStr)
  args = msgStr:lower():split(' ')
  
  if args[1] == 'stop' then
    follow_me = 0
    following = false
  elseif args[1] == 'follow' then
    if following then windower.send_ipc_message('stopfollowing '..following) end
    following = args[2]
    casting = nil
    target_pos = nil
    last_target_pos = nil
    windower.send_ipc_message('following '..following)
  elseif args[1] == 'following' then
    self = windower.ffxi.get_player()
    if not self or self.name:lower() ~= args[2] then return end
    follow_me = follow_me + 1
  elseif args[1] == 'stopfollowing' then
    self = windower.ffxi.get_player()
    if not self or self.name:lower() ~= args[2] then return end
    follow_me = follow_me - 1
  elseif args[1] == 'update' then
    if not following or args[2] ~= following then return end
    
    --windower.add_to_chat(0, msgStr)
    
    zoned = false
    target = {x=tonumber(args[4]), y=tonumber(args[5]), zone=tonumber(args[3])}
    
    if not last_target then last_target = target end
    
     if target.zone ~= -1 and (target.x ~= last_target.x or target.y ~= last_target.y or target.zone ~= last_target.zone) then
      last_target = target
    end
  end
end)

windower.register_event('prerender', function()
  if not follow_me and not following then return end
  
  if follow_me > 0 then
    local self = windower.ffxi.get_mob_by_target('me')
    local info = windower.ffxi.get_info()
    
    if not self and last_self then
      windower.send_ipc_message('update '..last_self.name..' -1 0 0')
    end
    
    last_self = self
    
    if not self or not info then return end
    
    args = T{'update', self.name , info.zone, self.x, self.y}
    --windower.add_to_chat(0, args:concat(' '))
    windower.send_ipc_message(args:concat(' '))
  elseif following then
    local self = windower.ffxi.get_mob_by_target('me')
    local info = windower.ffxi.get_info()
    
    if not self or not info then return end
    if casting then return windower.ffxi.run(false) end
    if not target then return windower.ffxi.run(false) end
    --if last_target and target.x == last_target.x and target.y == last_target.y then
    --  return windower.ffxi.run(false)
    --end
    
    if os.time() < zone_walk_end then return end
    if not zoned and target.zone == -1 and info.zone == last_target.zone then
      zone_walk_end = os.time() + zone_walk_duration
      zoned = true
      distSq = distanceSquared(last_target, self)
      len = math.sqrt(distSq)
      windower.ffxi.run(last_target.x - self.x, last_target.y - self.y)
      return
    end
    
    distSq = distanceSquared(target, self)
    len = math.sqrt(distSq)
    if len < 1 then len = 1 end
    
    if target.zone == info.zone and distSq > min_dist and distSq < max_dist then
      windower.ffxi.run((target.x - self.x)/len, (target.y - self.y)/len)
    else
      windower.ffxi.run(false)
    end
  end
end)

local PACKET_ID = { ACTION = 0x01A, USE_ITEM = 0x037 }
local PACKET_ACTION_CATEGORY = { MAGIC_CAST = 0x03, DISMOUNT = 0x12 }
local EVENT_ACTION_CATEGORY = { SPELL_FINISH = 4, ITEM_FINISH = 5, SPELL_BEGIN_OR_INTERRUPT = 8, ITEM_BEGIN_OR_INTERRUPT = 9 }
local EVENT_ACTION_PARAM = { BEGIN = 24931, INTERRUPT = 28787 }

windower.register_event('outgoing chunk', function(id, original, modified, injected, blocked)
  if blocked or casting or (id ~= PACKET_ID.ACTION and id ~= PACKET_ID.USE_ITEM) then return end
  
  if id == PACKET_ID.ACTION then
    if not pauseon:contains('spell') and not pauseon:contains('dismount') then return end
    
    local packet = packets.parse('outgoing', modified)
    if packet.Category ~= PACKET_ACTION_CATEGORY.MAGIC_CAST and packet.CATEGORY ~= PACKET_ACTION_CATEGORY.DISMOUNT then return end
    if packet.Category == PACKET_ACTION_CATEGORY.MAGIC_CAST and not pauseon:contains('spell') then return end
    if packet.Category == PACKET_ACTION_CATEGORY.DISMOUNT and not pauseon:contains('dismount') then return end
    
    local cast_time = os.time()
    casting = cast_time
    if pause_delay <= 0 then return end
    
    coroutine.schedule(function()
      packets.inject(packet)
    end, pause_delay)
    
    local delay = pause_dismount_delay
    if packet.Category == PACKET_ACTION_CATEGORY.MAGIC_CAST then
      -- TODO: Maybe get a little smarter, such as checking if the target is within range, we have sufficient mp, etc.
      local spell = spells[packet.Param]
      delay = spell.cast_time + 5.0
    end
    
    if co then coroutine.close(co) end
    co = coroutine.schedule(function()
      if casting ~= cast_time then return end
      casting = false
    end, pause_delay+delay)
    
    return true
  elseif id == PACKET_ID.USE_ITEM then
    if not pauseon:contains('item') then return end
    
    casting = os.time()
    if pause_delay <= 0 then return end
    
    local packet = packets.parse('outgoing', modified)
    
    local item = items[packet.Param]
    if not item or not item.cast_time then return end
    
    local cast_time = os.time()
    casting = cast_time
    
    coroutine.schedule(function()
      packets.inject(packets.parse('outgoing', modified))
    end, pause_delay)
    
    if co then coroutine.close(co) end
    co = coroutine.schedule(function()
      if casting ~= cast_time then return end
      casting = false
    end, pause_delay+item.cast_time)
    
    return true
  end
end)

windower.register_event('action', function(action)
  local player = windower.ffxi.get_player()
  if not player or action.actor_id ~= player.id then return end

  if action.category == EVENT_ACTION_CATEGORY.SPELL_FINISH or (action.category == EVENT_ACTION_CATEGORY.SPELL_BEGIN_OR_INTERRUPT and action.param == EVENT_ACTION_PARAM.INTERRUPT) then
    casting = false
  elseif action.category == EVENT_ACTION_CATEGORY.ITEM_FINISH or (action.category == EVENT_ACTION_CATEGORY.ITEM_BEGIN_OR_INTERRUPT and action.param == EVENT_ACTION_PARAM.INTERRUPT) then
    casting = false
  end
end)

function distanceSquared(A, B)
  local dx = B.x-A.x
  local dy = B.y-A.y
  return dx*dx + dy*dy
end