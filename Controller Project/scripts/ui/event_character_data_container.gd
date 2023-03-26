class_name EventCharacterDataContainer
extends VBoxContainer
# EventCharacterDataContainer's script.

const PAY_BTN: String = "Offer"
const DECLINE_BTN: String = "Decline Offer"
const LEAVE_BTN: String = "Leave"

const SYMBOL_BBCODE_TEXT_FORMAT: String = "[font=res://assets/fonts/ImgVerticalOffsetBitmapFont.tres][img=32]res://assets/sprites/symbols/%s.png[/img][/font]"
const EVENT_CHARACTER_PATH_FORMAT: String = "res://assets/sprites/event_characters/%s_event_character.png"

const FIRST_PAYER_MSGS: Dictionary = {
	Enums.Resource.CHEESE: "Hey you, yeah you! Got some cheese? If you give me at least %d%s. I'll give you %d%s! If I can't find a better deal that is.",
	Enums.Resource.ICE: "Good day to you! I'm looking for the finest ice that exists. I need %d%s, but the more the merrier. In return I'll offer you %d%s for your services.",
	Enums.Resource.LEAVES: "*stares*\ni... need... %d%s... more is good too.\ni'll give... %d%s...",
	Enums.Resource.SUPPORTER: "Your friendly neighbourhood postal pigeon here. My service costs %d%s. If your offer is the highest, I'll spread cool and rad leaflets about your candidacy in %s Area, increasing your voters by %d%%!",
	Enums.Resource.STEAL_SUPPORTER: "You've come to the right place. I want at least %d%s. If your offer is the highest, I'll spread negative propaganda about %s in %s Area, decreasing their voters by %d%% and increasing yours by %d%%!",
} 

const FIRST_PAYER_CAME_BACK_MSGS: Dictionary = {
	Enums.Resource.CHEESE: "Thanks for the %d%s, kiddo! I'll wait around a bit for other deals before accepting yours. Don't fret, if I find a better deal I'll give you back what you gave me.",
	Enums.Resource.ICE: "Thank you for your offer of %d%s. I hope you don't mind me waiting to see what others might offer. Be assured, I'll return what you gave me if I make a deal with someone else.",
	Enums.Resource.LEAVES: "*stares more*\nthanks for %d%s. i try ask someone else too.\ni return your leaves if someone give me more leaves.",
	Enums.Resource.SUPPORTER: "Aw shucks, thanks for offering %d%s. I'm kinda in a pinch, so if someone pays me more I'll have to do this service for them unfortunately. But don't worry, I play fair, I'll give you back your payment if that happens.",
	Enums.Resource.STEAL_SUPPORTER: "%d%s, ok. Better hope no one offers me more. I'll return your cash if they do though, don't want no extra trouble.",
}

const SECOND_PAYER_MSGS: Dictionary = {
	Enums.Resource.CHEESE: "Hey you! Someone already gave me a sweet deal for %d%s, can you beat it? I told them I wanted at least %d%s.",
	Enums.Resource.ICE: "One of your opponents offered me quite a bit of ice for %d%s. I can't reveal how much, but if you give me more the money is yours. I told your opponent I wanted at least %d%s.",
	Enums.Resource.LEAVES: "*stares and sweats*\nI give %d%s if you give more than other critter.\nmore than %d%s, please.",
	Enums.Resource.SUPPORTER: "Hi, a candidate payed me to spread propaganda about them in %s Area, which would increase their voters by %d%%. If you pay me more, I'll do it for you instead! The starting price was %d%s. Can't say what they payed me, policies and all that.",
	Enums.Resource.STEAL_SUPPORTER: "Someone already paid me to spread negative propaganda about %s in % Area, which would decrease their voters by %d%% and increase the payer's by %d%%. If you pay more, I'll do it in your name instead. Starting price is %d%s.",
}

const SECOND_PAYER_ACCEPTED_MSGS: Dictionary = {
	Enums.Resource.CHEESE: "You gave me %d%s more than that other fellow! I'll take it! Here's your %d%s. Hope to see you again kiddo.",
	Enums.Resource.ICE: "Nice, that's %d%s more than that other sucker! Here is your %d%s as part of our agreement. Pleasure doing business with you.",
	Enums.Resource.LEAVES: "*eyes sparkle*\n%d%s more than other! \ni accept. here... %d%s for you.",
	Enums.Resource.SUPPORTER: "By golly, that's a lot! You paid me %d%s more than that other candidate! I'm gonna head out right now to spread some leaflets about you and get you your %d%% voters.",
	Enums.Resource.STEAL_SUPPORTER: "Score! That's %d%s more than the previous guy. Rest assured you'll have your %d%% voters soon.",
}

const SECOND_PAYER_REFUSED_MSGS: Dictionary = {
	Enums.Resource.CHEESE: "Yeah... No, that other fellow offered me %d%s more. Better luck next time, champ.",
	Enums.Resource.ICE: "Unfortunately, I cannot accept. That is way too low, your opponent offered me %d%s more.",
	Enums.Resource.LEAVES: "*looks down*\num... um... no thanks. \nother critter give me %d%s more...",
	Enums.Resource.SUPPORTER: "Sorry, friend, that other candidate offered %d%s more. Nothing personal.",
	Enums.Resource.STEAL_SUPPORTER: "Way too low, the other candidate paid me %d%s more. Well, at least be happy you won't be losing any of your voters... for now.",
}

const TIED_MSGS: Dictionary = {
	Enums.Resource.CHEESE: "You were so close. The other fellow offered me the same but was first, so... Better luck next time, champ.",
	Enums.Resource.ICE: "Your offer is the same as the other one I received. I am terribly sorry, but I will have to go with whoever was first and unfortunately that's not you.",
	Enums.Resource.LEAVES: "*surprised*\nsame as other... but other was first...\nsorry...",
	Enums.Resource.SUPPORTER: "How unexpected! You gave me exactly the same offer! Unfortunately, my other client was first so I will have to go with them. Better luck next time!",
	Enums.Resource.STEAL_SUPPORTER: "Huh, you gave the same offer. Sorry, bud, the other guy was first.",
}

const REFUSED_MSGS: Dictionary = {
	Enums.Resource.CHEESE: "Your loss, buddy.",
	Enums.Resource.ICE: "I sincerely hope you do not regret this decision.",
	Enums.Resource.LEAVES: "*tears up*\nok... i go to someone else...",
	Enums.Resource.SUPPORTER: "That's ok, plenty of other fish in the sea. Or you know, breadcrumbs by the bench.",
	Enums.Resource.STEAL_SUPPORTER: "Just know, even if you don't play dirty that doesn't mean others won't.",
}

const CANNOT_STEAL_MSG: String = "Sorry, I don't do business with %s. Personal reasons."

onready var character_texture_rect: TextureRect = $CharacterTextureRect
onready var message_label: RichTextLabel = $DialoguePanel/MarginContainer/MessageRichTextLabel
onready var slider_container: HBoxContainer = $HSliderWithLabelContainer

# Sets the visual elements' values based on the given data. Returns the
# buttons to be removed based on the state.
func set_values(data: Dictionary) -> Array:
	_set_character_texture(data)
	var to_remove: Array
	if data.refused_by.has(PlayerData.id):
		_set_values_for_refused(data)
		to_remove = [PAY_BTN, DECLINE_BTN]
	elif not data.has_first_payment_been_made:
		to_remove = _set_values_for_first_visit(data)
	elif data.first_payment_by == PlayerData.id:
		_set_values_for_second_visit_by_first_payer(data)
		to_remove = [PAY_BTN, DECLINE_BTN]
	elif not data.has_event_ended:
		to_remove = _set_values_for_visit_by_second_payer(data)
	else:
		_set_values_for_event_ended(data)
		to_remove = [PAY_BTN, DECLINE_BTN]
	return to_remove

# Returns the slider_container's slider's value.
func get_slider_value() -> int:
	return slider_container.hslider.value


func _set_values_for_refused(data: Dictionary) -> void:
	slider_container.hide()
	var offer_type: int = _get_offer_type(data)
	message_label.bbcode_text = REFUSED_MSGS[offer_type]


func _set_values_for_first_visit(data: Dictionary) -> Array:
	if _show_cannot_steal_view_if_player_is_top_in_area(data):
		return [PAY_BTN, DECLINE_BTN]
	var offer_type: int = _get_offer_type(data)
	var take_res_symbol: String = _get_resource_symbol_as_bbcode_text(data.resource_type)
	var msg_args: Array = []
	if data.reward_type == Enums.Resource.MONEY:
		var give_res_symbol: String = _get_resource_symbol_as_bbcode_text(data.reward_type)
		msg_args = [data.min_payment, take_res_symbol, data.reward_amount, give_res_symbol]
	elif data.reward_type == Enums.Resource.SUPPORTER:
		var area_str: String = Enums.to_str(Enums.TileType, data.area)
		msg_args = [data.min_payment, take_res_symbol, area_str, data.reward_amount]
	elif data.reward_type == Enums.Resource.STEAL_SUPPORTER:
		var area_str: String = Enums.to_str(Enums.TileType, data.area)
		msg_args = [data.min_payment, take_res_symbol, TeamData.get_team_name_by_index(data.steal_from), area_str, data.reward_amount, data.reward_amount]
	message_label.bbcode_text = FIRST_PAYER_MSGS[offer_type] % msg_args
	_set_slider_visibility_based_on_player_resources(data)
	return []


func _set_values_for_second_visit_by_first_payer(data: Dictionary) -> void:
	slider_container.hide()
	var offer_type: int = _get_offer_type(data)
	var take_res_symbol: String = _get_resource_symbol_as_bbcode_text(data.resource_type)
	message_label.bbcode_text = FIRST_PAYER_CAME_BACK_MSGS[offer_type] % [
		data.first_payment_amount,
		take_res_symbol,
	]


func _set_values_for_visit_by_second_payer(data: Dictionary) -> Array:
	if _show_cannot_steal_view_if_player_is_top_in_area(data):
		return [PAY_BTN, DECLINE_BTN]
	var offer_type: int = _get_offer_type(data)
	var take_res_symbol: String = _get_resource_symbol_as_bbcode_text(data.resource_type)
	var msg_args: Array
	if data.reward_type == Enums.Resource.MONEY:
		var give_res_symbol: String = _get_resource_symbol_as_bbcode_text(data.reward_type)
		msg_args = [data.reward_amount, give_res_symbol, data.min_payment, take_res_symbol]
	elif data.reward_type == Enums.Resource.SUPPORTER:
		var area_str: String = Enums.to_str(Enums.TileType, data.area)
		msg_args = [area_str, data.reward_amount, data.min_payment, take_res_symbol]
	elif data.reward_type == Enums.Resource.STEAL_SUPPORTER:
		var area_str: String = Enums.to_str(Enums.TileType, data.area)
		msg_args = [TeamData.get_team_name_by_index(data.steal_from), area_str, data.reward_amount, data.reward_amount, data.min_payment, take_res_symbol]
	message_label.bbcode_text = SECOND_PAYER_MSGS[offer_type] % msg_args
	_set_slider_visibility_based_on_player_resources(data)
	return []


func _set_values_for_event_ended(data: Dictionary) -> void:
	slider_container.hide()
	var offer_type: int = _get_offer_type(data)
	var diff: int = int(abs(data.second_payment_amount - data.first_payment_amount))
	var take_res_symbol: String = _get_resource_symbol_as_bbcode_text(data.resource_type)
	if data.is_second_payer_successful:
		var msg_args: Array
		if data.reward_type == Enums.Resource.MONEY:
			var give_res_symbol: String = _get_resource_symbol_as_bbcode_text(data.reward_type)
			msg_args = [diff, take_res_symbol, data.reward_amount, give_res_symbol]
		else:
			msg_args = [diff, take_res_symbol, data.reward_amount]
		message_label.bbcode_text = SECOND_PAYER_ACCEPTED_MSGS[offer_type] % msg_args
	elif diff == 0:
		message_label.bbcode_text = TIED_MSGS[offer_type]
	else:
		message_label.bbcode_text = SECOND_PAYER_REFUSED_MSGS[offer_type] % [diff, take_res_symbol]


func _set_character_texture(data: Dictionary) -> void:
	var res_str: String
	if data.reward_type == Enums.Resource.MONEY:
		res_str = Enums.to_str_snake_case(Enums.Resource, data.resource_type)
	else:
		res_str = Enums.to_str_snake_case(Enums.Resource, data.reward_type)
	character_texture_rect.texture = load(EVENT_CHARACTER_PATH_FORMAT % res_str)


func _set_slider_visibility_based_on_player_resources(data: Dictionary) -> void:
	if PlayerData.resources[data.resource_type] >= data.min_payment:
		slider_container.show()
		slider_container.set_slider_values(
			data.min_payment, 
			PlayerData.resources[data.resource_type], 
			data.min_payment)
	else:
		slider_container.hide()


func _get_offer_type(data: Dictionary) -> int:
	var offer_type: int = data.resource_type
	if data.reward_type != Enums.Resource.MONEY:
		offer_type = data.reward_type
	return offer_type


func _get_resource_symbol_as_bbcode_text(res: int) -> String:
	var res_str: String = Enums.to_str_snake_case(Enums.Resource, res)
	return SYMBOL_BBCODE_TEXT_FORMAT % res_str


func _show_cannot_steal_view_if_player_is_top_in_area(data: Dictionary) -> bool:
	if data.reward_type == Enums.Resource.STEAL_SUPPORTER and \
		data.steal_from == PlayerData.team_index:
		slider_container.hide()
		#var area_str: String = Enums.to_str(Enums.TileType, data.area)
		message_label.bbcode_text = CANNOT_STEAL_MSG % TeamData.get_team_name_by_index(data.steal_from)
		return true
	return false
