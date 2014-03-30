require "defines"

TREETYPES = {
	nil, -- Random
	"dark-thin-tree",
	"green-thin-tree",
	"dark-green-thin-tree",
	"green-tree",
	"dark-green-tree"
}

CONTROLLER_RADIUS=7

game.oninit(function()
	initTables()
end)


game.onload(function()
	initTables()
end)

table.indexOf = function( t, object )
	local result
	 
	if "table" == type( t ) then
		for i=1,#t do
			if object == t[i] then
				result = i
				break
			end
		end
	end
	 
	return result
end

function tableContains(t, element)
	for _, value in pairs(t) do
		if value == element then
			return true
		end
	end
	return false
end

function iTableContains(t, element)
	for _, value in ipairs(t) do
		if value == element then
			return true
		end
	end
	return false
end

function bbox2Rect(bbox)
	return {
		{bbox[1].x,bbox[1].y},
		{bbox[2].x,bbox[2].y}
	}
end

-- From Testing Mode
function isHolding(stack)
  local holding = game.player.cursorstack
  if (holding.name == stack.name) and (holding.count >= stack.count) then
    return true
  end

  return false
end

game.onevent(defines.events.onputitem, function(event)
	if isHolding({name="ag-controller", count=1}) then
		local selectedEnt = game.player.selected
		if selectedEnt and selectedEnt.valid and selectedEnt.name == "ag-controller" then
			for k, zone in pairs(glob.agriculture.zones) do
				if zone.controller.valid and zone.controller.equals(selectedEnt) then
					openZoneSettings(zone)
					return
				end
			end
			createZoneFor(selectedEnt)
			for k, zone in pairs(glob.agriculture.zones) do
				if zone.controller.valid and zone.controller.equals(selectedEnt) then
					openZoneSettings(zone)
					return
				end
			end
		end
	end
end)

game.onevent(defines.events.onguiclick, function(event)
	local context = glob.agriculture.context
	if event.element.name == "ag-deforest" then
		context.deforest = not context.deforest
	elseif event.element.name == "ag-replant" then
		context.replant = not context.replant
	elseif event.element.name == "ag-treetype" then
		local tti = table.indexOf(TREETYPES,context.typepref)
		if tti == nil then tti = 1 end
		tti = tti + 1
		if tti > #TREETYPES then 
			tti = 1 
		end
		context.typepref = TREETYPES[tti]
		local typecap = context.typepref
		if typecap == nil then 
			typecap="Random" 
		end
		--game.player.print("Zone will now attempt to grow trees of type "..typecap.." ("..tti..")")
		game.player.gui.center.agframe.settings["ag-treetype"].caption=typecap
	elseif event.element.name == "ag-clear" then
		local germlings = game.findentitiesfiltered{area = context.bbox, name="germling"}
		for _, germling in pairs(germlings) do
			if germling.valid and not germling.tobedeconstructed(game.player.force) then
				germling.orderdeconstruction(game.player.force)
			end
		end
		if context.typepref ~= nil then
			local trees = game.findentitiesfiltered{area = context.bbox, type="tree"}
			for _, tree in pairs(trees) do
				if tree.valid and detectTreeStatus(tree) == 5 and tree.name ~= context.typepref and not tree.tobedeconstructed(game.player.force) then
					tree.orderdeconstruction(game.player.force)
				end
			end
		end
	elseif event.element.name == "ag-save" then
		closeZoneSettings()
	end
end)

game.onevent(defines.events.onentitydied, function(event)
	if event.entity.name == "ag-controller" then
		checkZoneValidity()
	end
end)

function closeZoneSettings()
	gui = game.player.gui.center
	if glob.agriculture.context ~= nil then
		glob.agriculture.context.stop=false
	end
	glob.agriculture.context=nil
	if gui.agframe then 
		gui.agframe.destroy()
	end
end

function openZoneSettings(zone)
	gui = game.player.gui.center
	if gui.agframe then 
		closeZoneSettings()
	end
	zone.stop=true
	glob.agriculture.context=zone
	gui.add({ type="frame",direction="horizontal", name="agframe", caption="Agriculture Zone Settings" })
	
	gui.agframe.add({ type="table", name="settings", colspan=2 })
	
	gui.agframe.settings.add({ type="label", caption="Clear Grown Trees:" })
	gui.agframe.settings.add({ type="checkbox", name="ag-deforest", state = zone.deforest })
	
	gui.agframe.settings.add({ type="label", caption="Plant Seeds:" })
	gui.agframe.settings.add({ type="checkbox", name="ag-replant", state = zone.replant })
	
	gui.agframe.settings.add({ type="label", caption="Tree type:"})
	local treecap = zone.typepref
	if treecap == nil then
		treecap = "Random"
	end
	gui.agframe.settings.add({ type="button", name="ag-treetype", caption=treecap })
	
	gui.agframe.settings.add({ type="button", name="ag-clear", caption="CLEAR" })
	gui.agframe.settings.add({ type="button", name="ag-save", caption="Close" })
end

function checkZoneValidity()
	for k, zone in ipairs(glob.agriculture.zones) do
		if not zone.controller.valid then
			table.remove(glob.agriculture.zones, k)
			break
		end
	end
end

game.onevent(defines.events.onplayermineditem, function(event)
	if event.itemstack.name == "ag-controller" then
		checkZoneValidity()
	end	
end)

function createZoneFor(entity)
	local newzone = {
		controller = entity,
		bbox = {
			{x = entity.position.x - CONTROLLER_RADIUS, y = entity.position.y - CONTROLLER_RADIUS},
			{x = entity.position.x + CONTROLLER_RADIUS, y = entity.position.y + CONTROLLER_RADIUS}
		},
		deforest = false,
		replant = false,
		typepref = nil,
		stop = false
	}
	local efficiency = {
		calcEfficiency({x = newzone.bbox[1].x, y = newzone.bbox[1].y}),
		calcEfficiency({x = newzone.bbox[2].x, y = newzone.bbox[1].y}),
		calcEfficiency({x = newzone.bbox[1].x, y = newzone.bbox[2].y}),
		calcEfficiency({x = newzone.bbox[2].x, y = newzone.bbox[2].y})
	}
	
	if (efficiency[1] == 0) or (efficiency[2] == 0) or (efficiency[3] == 0) or (efficiency[4] == 0) then
		entity.destroy()
		game.player.character.insert{name="ag-controller", count=1}
		game.player.print("The soil is too poor.")
		return false
	end
	
	newzone.efficiency = (efficiency[1] + efficiency[2] + efficiency[3] + efficiency[4]) / 4
	glob.agriculture.zones[#glob.agriculture.zones + 1] = newzone
	openZoneSettings(newzone)
	return true
end

game.onevent(defines.events.onbuiltentity, function(event)
	if event.createdentity.name == "ag-controller" then
		createZoneFor(event.createdentity)
	end
end)

function detectTreeStatus(entity)
	if     entity.name == "germling"        then return 1
	elseif entity.name == "very-small-tree" then return 2
	elseif entity.name == "small-tree"      then return 3
	elseif entity.name == "medium-tree"     then return 4
	elseif	(entity.name == "dark-thin-tree") or
			(entity.name == "green-thin-tree") or
			(entity.name == "dark-green-thin-tree") or
			(entity.name == "green-tree") or
			(entity.name == "dark-green-tree")
			then
				return 5
	end
end
function detectObstaclesAt(pos)
	local detected = game.findentities{
		{pos.x-1,pos.y-1},
		{pos.x+1,pos.y+1}
	}
	local ignore_names={
		"smoke",
		"item-on-ground",
		"iron-ore",
		"copper-ore"
	}
	local names = {}
	for _,ent in pairs(detected) do
		if ent.valid and not tableContains(ignore_names,ent.name) then
			if not tableContains(names,ent.name) then
				names[#names+1]=ent.name
			end
		end
	end
	return names
end

game.onevent(defines.events.ontick, function(event)
	glob.agriculture.tick = glob.agriculture.tick + 1
	if (glob.agriculture.tick % 60) == 0 then
		for k, zone in pairs(glob.agriculture.zones) do
			if zone.controller.valid and not zone.stop then
				local growchance = math.ceil(math.random()* 100)
				remote.call("treefarm","checktrees",{area = zone.bbox, typepref = zone.typepref})
				local growntrees = game.findentitiesfiltered{area = zone.bbox, type="tree"}
				if (growchance > 95) then
					--if math.random() <= zone.efficiency then
						local treeplaced = false					
						-- Loop maximum of 49 times.
						for loop=0,49 do
							local growntree = {}
							local treeposition ={}
							treeposition.x = math.floor(math.random()*(zone.bbox[2].x-zone.bbox[1].x)) + zone.bbox[1].x
							treeposition.y = math.floor(math.random()*(zone.bbox[2].y-zone.bbox[1].y)) + zone.bbox[1].y
							growntree = game.findentitiesfiltered{area = {treeposition, treeposition}, type="tree"}
							if #growntree > 1 then
								for id=2,#growntree do
									growntree[id].destroy()
								end
							end
							if growntree[1] ~= nil then 
								break 
							end
							
							-- Now we're just checking to see if there's enough room since canplaceentity doesn't give a fuck about trees.
							obstacles = detectObstaclesAt(treeposition)
							if #obstacles == 0 then
								if #growntrees < 40 and zone.replant and zone.controller.getitemcount("seeds") > 0 then
									--game.createentity{name = "big-tree", position = treeposition}
									if game.canplaceentity{name="lab", position = treeposition} then
										zone.controller.getinventory(1).remove{name = "seeds", count = 1}
										addTreeToFarm(treeposition,1,zone.typepref)
										--game.player.print("Added germling at pos "..serpent.dump(treeposition))
										treeplaced = true
										break
									end
								else
									break
								end
							else
								--addTreeToFarm(growntree[1],0)
							end
						end -- (treeplaced~= true)
					--end
				end -- (growchance > 99) and (#growntrees < 40)
			end
		end -- _, field in ipairs(glob.treefarm.field)
	end -- (glob.treefarm.tick % 60) == 0
--[[
	if (glob.agriculture.tick % 1200) == 0 then		
		for _, zone in ipairs(glob.agriculture.zones) do
			if zone.controller.valid then
				if zone.controller.getitemcount("fertilizer") > 0 then
					zone.controller.getinventory(1).remove{name = "fertilizer", count = 1}
				end
			end
		end -- _, field in ipairs(glob.treefarm.field)
	end -- ((glob.treefarm.tick + 30) % 60) == 0
]]--
	if (glob.agriculture.tick % (300 + math.ceil(math.random()*300))) == 0 then		
		for k, zone in pairs(glob.agriculture.zones) do
			if zone.controller.valid and zone.deforest and not zone.stop then	
				local bb = bbox2Rect(zone.bbox)
				local growntrees = game.findentitiesfiltered{area = bb, type="tree"}
				if #growntrees > 5 then
					-- This is a predictable pattern, but I'd rather not deal with a table being resized while it's being iterated.
					local rnd_out = math.ceil(math.random()*5)
					local trees_cut = 0
					for _, tree in pairs(growntrees) do
						if tree.valid --[[and trees_cut + 1 <= rnd_out]] and detectTreeStatus(tree)==5 and not tree.tobedeconstructed(game.player.force) then
							tree.orderdeconstruction(game.player.force)
							trees_cut = trees_cut + 1
						end
					end
					checkZoneValidity()
					--game.player.print("Found "..#growntrees.." grown trees, "..trees_cut.." of which are being harvested.")
				else
					--game.player.print("Found "..#growntrees.." grown trees.")
				end
			end
		end
	end
end)


function calcEfficiency(position)

	local efficiency = 0
	local x,y, samples
	samples=0
	for x = -7, 7, 7 do
		for y = -7, 7 , 7 do
			if game.gettile(position.x + x, position.y + y).name == "grass" then
				efficiency = efficiency + 1.00
			elseif game.gettile(position.x + x, position.y + y).name == "dirt" then
				efficiency = efficiency + 0.95
			elseif game.gettile(position.x + x, position.y + y).name == "hills" then
				efficiency = efficiency + 0.70
			elseif game.gettile(position.x + x, position.y + y).name == "sand" then
				efficiency = efficiency + 0.60
			else
				efficiency = efficiency + 0.00
			end
			samples = samples + 1
		end
	end

	efficiency = efficiency / samples
	return efficiency
end


function calcTreeEfficiency(position)
	local tileName = game.gettile(position.x, position.y).name
	local tileInfo = glob.agriculture.tile_info[tileName]
	if tileInfo == nil then
		return 0.00
	else
		return tileInfo.efficiency
	end
end

function initTables()
	if glob.agriculture == nil then
		glob.agriculture = {}
	end

	if glob.agriculture.zones == nil then
		glob.agriculture.zones = {}
	end

	if glob.agriculture.tick == nil then
		glob.agriculture.tick = 0
	end

	if glob.agriculture.efficiency == nil then
		glob.agriculture.efficiency = {}
	end
	if glob.agriculture.tile_info == nil then
		-- if game.gettile(position.x, position.y).name == "grass" then
		glob.agriculture.tile_info = {
			["grass"] = {
				efficiency = 1.00
			},
			["grass-medium"] = {
				efficiency = 1.00
			},
			["grass-dry"] = {
				efficiency = 1.00
			},
			["dirt"] = {
				efficiency = 0.95
			},
			["dirt-dark"] = {
				efficiency = 0.95
			},
			["hills"] = {
				efficiency = 0.70
			},
			["sand"] = {
				efficiency = 0.60
			},
			["sand-dark"] = {
				efficiency = 0.60
			},
			["default"] = {
				efficiency = 0.00
			}
		}
	end
	--game.player.print("Agriculture tables installed.")
end


function haxAgriculture()
	game.player.force.technologies["agriculture"].researched = true
end

--[[ For reference.
function growTrees()
	if (glob.treefarm.tick % (60 + math.floor(math.random()*120))) == 0 then
		for k, tree in pairs(glob.treefarm.growingTrees.entities) do
			if tree.valid then
				local growchance = math.random()
				local efficiency = math.random()

				if (growchance >= 0.99) and (efficiency <= glob.treefarm.growingTrees.efficiency[k]) then
					updateTree(k)
					--break
				end
			end
		end
	end
end


function updateTree(k)

	local tmpPos

	glob.treefarm.growingTrees.status[k] = glob.treefarm.growingTrees.status[k] + 1

	if glob.treefarm.growingTrees.status[k] == 2 then		-- very small tree
		tmpPos = glob.treefarm.growingTrees.entities[k].position
		glob.treefarm.growingTrees.entities[k].destroy()
		table.remove(glob.treefarm.growingTrees.entities, k)
		table.insert(glob.treefarm.growingTrees.entities, k , game.createentity{name = "very-small-tree", position = tmpPos})

	elseif glob.treefarm.growingTrees.status[k] == 3 then		-- small tree
		tmpPos = glob.treefarm.growingTrees.entities[k].position
		glob.treefarm.growingTrees.entities[k].destroy()
		table.remove(glob.treefarm.growingTrees.entities, k)
		table.insert(glob.treefarm.growingTrees.entities, k , game.createentity{name = "small-tree", position = tmpPos})

	elseif glob.treefarm.growingTrees.status[k] == 4 then		-- medium tree
		tmpPos = glob.treefarm.growingTrees.entities[k].position
		glob.treefarm.growingTrees.entities[k].destroy()
		table.remove(glob.treefarm.growingTrees.entities, k)
		table.insert(glob.treefarm.growingTrees.entities, k , game.createentity{name = "medium-tree", position = tmpPos})

	elseif glob.treefarm.growingTrees.status[k] == 5 then		-- big tree
		tmpPos = glob.treefarm.growingTrees.entities[k].position
		glob.treefarm.growingTrees.entities[k].destroy()
		table.remove(glob.treefarm.growingTrees.entities, k)
		--table.remove(glob.treefarm.growingTrees.efficiency, k)
		--table.remove(glob.treefarm.growingTrees.status, k)
		local tmpRandom = math.random(5)
		local treeType = "dark-thin-tree"
		if tmpRandom == 1 then
			treeType = "dark-thin-tree"
		elseif tmpRandom == 2 then
			treeType = "green-thin-tree"
		elseif tmpRandom == 3 then
			treeType = "dark-green-thin-tree"
		elseif tmpRandom == 4 then
			treeType = "green-tree"
		elseif tmpRandom == 5 then
			treeType = "dark-green-tree"
		end
		table.insert(glob.treefarm.growingTrees.entities, k, game.createentity{name = treeType, position = tmpPos})
	end

end
]]--

remote.addinterface("agriculture",
{
  dump = function()
		game.showmessagedialog(serpent.line(glob.agriculture))
  end
})

function addTreeToFarm(entitypos, status, typepref)
	--game.player.print("Received addtree: "..typepref)
	remote.call("treefarm","addtree", entitypos, status, typepref)
end