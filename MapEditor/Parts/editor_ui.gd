extends Control


func _ready():
	%EnvironmentButton.pressed.connect(func a():
		display_properties(%Environment, %Environment.environment)
		)
	%PropertiesPanel.hide()

func display_properties(entity, resource = null):
	%PropertiesPanel.show()
	
	
	for i in %PropertiesList.get_children(): i.queue_free()
	
	if not resource: resource = entity
	
	#if resource is Environment:
		#resource = resource.merge(resource.sky)
	var properties = Utility.get_entity_properties(entity)
	
	#print("\n\n\n")
	#print(properties)
	#print("\n\n\n")
	#print(resource.get_property_list())
	#print("\n\n\n")
	
	for section in properties.keys():
		if section == "hidden": continue
		
		var section_inst = preload("res://MapEditor/Parts/section.tscn").instantiate()
		%PropertiesList.add_child(section_inst)
		section_inst.get_child(0).text = section
		
		
		#if section == "Sky":
			#properties[section] = {
				#"sky_top_color": resource.sky.sky_material.sky_top_color,
				#"sky_horizon_color": resource.sky.sky_material.sky_horizon_color,
				#"ground_bottom_color": resource.sky.sky_material.ground_bottom_color,
				#"ground_horizon_color": resource.sky.sky_material.ground_horizon_color
			#}
		
		
		# fix this shortterm solution
		#if section == "Material":
			#resource = resource.material_override
			#properties["Material"] = {"albedo_color": resource.albedo_color}
		
		display_properties_subfunc(properties, section, section_inst, entity)


func display_properties_subfunc(properties, section, section_inst, entity):
	
	for property in properties[section].keys():
		
		#if property == "sky_top_color" or property == "sky_horizon_color" or property == "ground_bottom_color" or property == "ground_horizon_color": data_type = Variant.Type.TYPE_COLOR
		
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
		
		var data_type
		if not data_type:
			for res in entity.ENTITY_RESOURCES:
				for prop in res.get_property_list():
					if prop.name == property:
						data_type = prop.type
		
		var value = properties[section][property]
		
		make_new_field(value, data_type, entity, property, property_inst)


func make_new_field(value, data_type, entity, property, property_inst):
	
	var new_field
	match data_type:
		Variant.Type.TYPE_INT, Variant.Type.TYPE_FLOAT, Variant.Type.TYPE_VECTOR3, Variant.Type.TYPE_STRING:
			new_field = LineEdit.new()
			
			new_field.text_submitted.connect(
				func text_submitted(new_text):
					
					var new_value
					match data_type:
						Variant.Type.TYPE_INT:
							new_value = int(new_text)
						Variant.Type.TYPE_FLOAT:
							new_value = float(new_text)
						Variant.Type.TYPE_VECTOR3:
							var string = "Vector3"+new_text
							new_value = str_to_var(string)
						Variant.Type.TYPE_STRING:
							new_value = new_text
					
					set_resources_property(entity, property, new_value)
					print("PROP: %s, VALUE: %s" % [property, new_value])
					new_field.release_focus()
			)
			
			
			new_field.text = str(value)
		
		
		Variant.Type.TYPE_COLOR:
			new_field = ColorPickerButton.new()
			
			new_field.color_changed.connect(
				func color_changed(color):
					
					set_resources_property(entity, property, color)
					#if property == "sky_top_color" or property == "sky_horizon_color" or property == "ground_bottom_color" or property == "ground_horizon_color":
						#resource.sky.sky_material.set(property, color)
					#else:
						#resource.set(property, color)
			)
			
			new_field.color = value
		
		Variant.Type.TYPE_BOOL:
			new_field = CheckBox.new()
			
			new_field.toggled.connect(
				func toggled(toggled_on):
					set_resources_property(entity, property, toggled_on)
			)
			
			new_field.button_pressed = value
		
		Variant.Type.TYPE_OBJECT:
			property_inst.queue_free()
		
		Variant.Type.TYPE_ARRAY:
			var vbox = VBoxContainer.new()
			property_inst.add_child(vbox)
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			for i in value.size():
				for key in value[i].keys():
					
					var val = value[i][key]
					var type = typeof(val)
					
					var x = "!"+str(property)+"["+str(i)+"{"+str(key)#+"="+str(val)
					var field = make_new_field(val, type, entity, x, property_inst)
					field.reparent(vbox)
					#vbox.add_child(field)
		
		_: push_error("DATA TYPE UNSUPPORTED: %d" % data_type)
	
	if new_field:
		property_inst.add_child(new_field)
		new_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return new_field

func set_resources_property(entity, property : String, value):
	if property[0] == "!":
		property = property.substr(1)
		
		var prop
		var index
		var key
		
		for i in property.length():
			if property[i] == "[":
				prop = property.substr(0, i)
			if property[i] == "{":
				index = int(property.substr(prop.length()+1, i-1))
				key = property.substr(i+1)
		
		var v = value
		value = entity.get(prop)
		value[index][key] = v
		
		if prop in entity:
			entity.set(prop, value)
	
	else:
		for res in entity.ENTITY_RESOURCES:
			if property in res:
				res.set(property, value)
