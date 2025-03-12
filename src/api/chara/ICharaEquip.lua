local Event = require("api.Event")
local EquipSlots = require("api.EquipSlots")
local ICharaInventory = require("api.chara.ICharaInventory")
local data = require("internal.data")
local Enum = require("api.Enum")
local IItemEquipment = require("mod.elona.api.aspect.IItemEquipment")
local EquipRules = require("api.chara.EquipRules")
local ICharaEquipStyle = require("api.chara.aspect.ICharaEquipStyle")

local ICharaEquip = class.interface("ICharaEquip", {}, ICharaInventory)

function ICharaEquip:init()
   self.body_parts = self.body_parts or {}
   self.equip = EquipSlots:new(self.body_parts, self)
   self.equipment_weight = 0

   self:get_aspect_or_default(ICharaEquipStyle, true)
end

local function apply_item_enchantments(chara, item)
   -- >>>>>>>> shade2/calculation.hsp:448 	repeat maxItemEnc ..
   for _, merged_enc in item:iter_merged_enchantments() do
      if merged_enc.proto.on_refresh then
         merged_enc.proto.on_refresh(merged_enc.total_power, merged_enc.params, item, chara)
      end
   end
   -- <<<<<<<< shade2/calculation.hsp:492 	loop ..
end

local function apply_item_stats(chara, item)
   -- >>>>>>>> shade2/calculation.hsp:434 	cEqWeight(r1)+=iWeight(rp) ..
   chara:mod("equipment_weight", item:calc("weight"), "add")

   local equip = assert(item:get_aspect(IItemEquipment), item._id)
   chara:mod("dv", equip:calc(item, "dv"), "add")
   chara:mod("pv", equip:calc(item, "pv"), "add")

   if EquipRules.is_melee_weapon(item) then
      -- chara:mod("number_of_weapons", 1, "add")
   end

   if EquipRules.is_armor(item) then
      chara:mod("hit_bonus", equip:calc(item, "hit_bonus"), "add")
      chara:mod("damage_bonus", equip:calc(item, "damage_bonus"), "add")
      local bonus = 0
      if item:is_blessed() then
         bonus = 2
      end
      chara:mod("pv", item:calc("bonus") * 2 + bonus, "add")
   end

   local curse_state = item:calc("curse_state")
   if curse_state == Enum.CurseState.Cursed then
      chara:mod("curse_power", 20, "add")
   elseif curse_state == Enum.CurseState.Cursed then
      chara:mod("curse_power", 100, "add")
   end

   local material = item:calc("material")
   if material then
      local material_proto = data["elona.item_material"]:ensure(material)
      if material_proto.on_equipper_refresh then
         material_proto.on_equipper_refresh(chara, item)
      end
   end
   -- <<<<<<<< shade2/calculation.hsp:446 	if iMaterial(rp)=mtEther : if r1=pc : gEtherSpeed ...

   apply_item_enchantments(chara, item)

   Event.trigger("base.on_calc_chara_equipment_stats", {chara=chara,item=item})
end

function ICharaEquip:iter_merged_enchantments()
   local iters = self:iter_equipment():map(
      function(i)
         local enc_iter = i:iter_merged_enchantments();
         -- (i, enc) -> (i, enc, item_with_enc)
         local item_dup = fun.duplicate(i)
         return fun.zip(enc_iter, item_dup)
      end):to_list()
   return fun.chain(table.unpack(iters))
end

function ICharaEquip:find_merged_enchantment(_id)
   data["base.enchantment"]:ensure(_id)
   return self:iter_merged_enchantments():filter(function(enc) return enc._id == _id end):nth(1)
end

function ICharaEquip:enchantment_power(_id, params, source)
   return self:iter_equipment():map(function(i) return i:enchantment_power(_id, params, source) end):sum()
end

function ICharaEquip:on_refresh()
   for _, part in self:iter_equipped_body_parts() do
      local item = assert(part.equipped)
      item:refresh()

      apply_item_stats(self, item)
   end

   self:get_aspect(ICharaEquipStyle):refresh_melee_equip_style(self)
end

function ICharaEquip:equip_item(item, force, slot)
   if not self:has_item(item) then
      if force then
         if not self:take_item(item) then
            return nil, "cannot_take"
         end
      else
         return nil, "not_owned"
      end
   end

   local result, err = self.equip:equip(item, slot)
   item:refresh()

   return result, err
end

function ICharaEquip:has_item_equipped(item)
   return self.equip:has_object(item)
end

function ICharaEquip:iter_items_equipped_at(body_part_type)
   return self.equip:iter_items_equipped_at(body_part_type)
end

function ICharaEquip:find_equip_slot_for(item, body_part_type)
   return self.equip:find_free_slot(item, body_part_type)
end

-- Returns true if the given item is equipped or in the character's
-- inventory.
function ICharaEquip:has_item(item)
   return self:has_item_in_inventory(item) or self:has_item_equipped(item)
end

function ICharaEquip:unequip_item(item)
   if not self.equip:has_object(item) then
      return nil
   end

   local result = self:take_item(item)
   item:stack()
   item:refresh()

   return result
end

-- Iterates the body parts on this character that have equipment
-- @treturn iterator
function ICharaEquip:iter_equipped_body_parts(also_blocked)
   return self.equip:iter_equipped_body_parts(also_blocked)
end

-- Iterates all body parts on this character, including empty slots.
-- @treturn iterator
function ICharaEquip:iter_all_body_parts(also_blocked)
   return self.equip:iter_all_body_parts(also_blocked)
end

-- Iterates the items that are equipped on this character.
-- @treturn iterator
function ICharaEquip:iter_equipment()
   return self.equip:iter()
end

function ICharaEquip:body_part_count(body_part_id)
   return self.equip:body_part_count(body_part_id)
end

function ICharaEquip:has_body_part_for(item)
   return self.equip:has_body_part_for(item)
end

-- Adds a new body part to this character.
-- @tparam base.body_part _type
function ICharaEquip:add_body_part(_type)
   self.equip:add_body_part(_type)
end

function ICharaEquip:get_equip_slot(index)
   return self.equip:get(index)
end

-- Attempts to remove a body part. If something is equipped there,
-- this function fails unless `force` is true. If `force` is true when
-- an item is equipped there, removes the item, makes it ownerless and
-- returns it. If unsuccessful, no state is changed.
-- @tparam int|string type_or_slot
-- @tparam bool force
-- @treturn[1] nil
-- @treturn[2] IItem
-- @retval_ownership nil
function ICharaEquip:remove_body_part(type_or_slot, force)
   -- TODO
end

-- Marks a body part type as "blocked" for use as a refreshed value. All slots
-- with that body part type will be hidden in the equipment menu for the
-- character, and will also not show up in the results of iterators.
function ICharaEquip:set_body_part_blocked(body_part_id, blocked)
   self.equip:set_body_part_blocked(body_part_id, blocked)
end

return ICharaEquip
