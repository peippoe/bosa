extends Control


func _ready():
	%EnvironmentButton.pressed.connect(func a():
		display_properties(%Environment, %Environment.environment)
		)


func display_properties(entity, resource = null):
	
	for i in %PropertiesList.get_children(): i.queue_free()
	
	if not resource: resource = entity
	var properties = Utility.get_entity_properties(entity, resource)
	
	for section in properties.keys():
		var section_inst = preload("res://MapEditor/Parts/section.tscn").instantiate()
		%PropertiesList.add_child(section_inst)
		section_inst.get_child(0).text = section
		
		if section == "Background":
			properties[section] = {
				"background_color": Color.WHITE
			}
		
		for property in properties[section].keys():
			
			var data_type
			if property == "color": data_type = Variant.Type.TYPE_COLOR
			
			
			
			var property_inst = preload("res://MapEditor/Parts/property.tscn").instantiate()
			section_inst.add_child(property_inst)
			
			property_inst.name = property
			
			var property_name : String = property
			
			#var cutoff = property_name.find("_") + 1
			#property_name = property_name.substr(cutoff)
			
			#for i in property_name.length():
				#if property_name[i] == "_":
					#property_name[i] = " "
			
			property_inst.get_child(0).text = property_name
			
			
			if not data_type:
				for prop in resource.get_property_list():
					if prop.name == property:
						data_type = prop.type
			
			
			var new_field
			match data_type:
				Variant.Type.TYPE_INT, Variant.Type.TYPE_FLOAT, Variant.Type.TYPE_VECTOR3:
					print("line_edit")
					new_field = LineEdit.new()
					
					new_field.text_submitted.connect(
						func text_submitted(new_text):
							
							var value
							match data_type:
								Variant.Type.TYPE_INT:
									value = int(new_text)
								Variant.Type.TYPE_FLOAT:
									value = float(new_text)
								Variant.Type.TYPE_VECTOR3:
									value = Vector3(new_text)
							
							resource.set(property, value)
							print(%Environment.environment.tonemap_mode)
					)
				
				Variant.Type.TYPE_COLOR:
					new_field = ColorPickerButton.new()
					
					new_field.color_changed.connect(
						func color_changed(color):
							resource.set(property, color)
					)
					
				
				_: print("DATA TYPE UNSUPPORTED: %d" % data_type)
			
			property_inst.add_child(new_field)
			new_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			if "text" in new_field:
				print("IT HAS TEXT")
				new_field.text = str(properties[section][property])
