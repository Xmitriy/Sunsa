local DateTime = require("api.DateTime")
local Event = require("api.Event")
local CircularBuffer = require("api.CircularBuffer")
local StayingCharas = require("api.StayingCharas")

local function init_save()
   local s = save.elona
   s.turns_until_cast_return = 0
   s.return_destination_map_uid = nil
   s.return_destination_map_x = nil
   s.return_destination_map_y = nil
   s.well_wish_count = 0
   s.holy_well_count = 0
   s.guild = nil
   s.artifact_locations = {}
   s.inheritable_item_count = 0
   s.fire_giant_uid = nil
   s.is_fire_giant_released = false
   s.home_rank = "elona.cave"
   s.flag_has_met_ally = false
   s.total_skills_learned = 0
   s.waiting_guests = 0
   s.player_owned_buildings = {}
   s.is_lomias_easter_egg_enabled = false
   s.ranks = {}
   s.weather_id = "elona.sunny"
   s.turns_until_weather_changes = 0
   s.date_of_last_etherwind = DateTime:new()
   s.next_train_date = 0
   s.date_of_last_guest_trainer_visit = DateTime:new()
   s.lost_wallets_reported = 0
   s.labor_expenses = 0
   s.unpaid_bill_count = 0
   s.about_to_regenerate_world_map = false
   s.about_to_regenerate_nefias = false
   s.guild_mage_point_quota = 0
   s.guild_fighter_target_chara_id = nil
   s.guild_fighter_target_chara_quota = 0
   s.guild_thief_stolen_goods_quota = 0
   s.flag_fools_magic_stone = false
   s.flag_kings_magic_stone = false
   s.flag_sages_magic_stone = false
   s.news_buffer = CircularBuffer:new(38)
   s.staying_adventurers = StayingCharas:new(nil)
   s.ex_help_shown = {}
   s.shortcuts = {}
   s.flag_kamikaze_attack = 0
   s.little_sisters_killed = 0
   s.little_sisters_saved = 0
   s.strange_scientist_gifts_given = 0
end

Event.register("base.on_init_save", "Init save (elona)", init_save)
