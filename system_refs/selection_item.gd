# selection_item.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright (c) 2017-2019 Charlie Whitfield
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# *****************************************************************************
#

extends Reference
class_name SelectionItem

const ECLIPTIC_NORTH := Vector3(0.0, 0.0, 1.0)
enum SelectionType {
	# I, Voyager doesn't use the first three
	SELECTION_UNIVERSE,
	SELECTION_GALAXY,
	SELECTION_STAR_COLLECTION,
	SELECTION_STAR_SYSTEM, # used as generic term for Solar System (there isn't one!)
	SELECTION_BARYCENTER,
	SELECTION_LAGRANGE_POINT,
	SELECTION_STAR,
	SELECTION_PLANET,
	SELECTION_DWARF_PLANET,
	SELECTION_MOON,
	SELECTION_MINOR_MOON, # arbitrary designation for display purposes
	SELECTION_ASTEROIDS,
	SELECTION_ASTEROID_GROUP,
	SELECTION_COMMETS,
	SELECTION_SPACECRAFTS,
	SELECTION_ASTEROID,
	SELECTION_COMMET,
	SELECTION_SPACECRAFT
	}

# persisted - read only
var name: String # Registrar guaranties these are unique
var selection_type: int
var classification: String
var is_body: bool
var up_selection_name := ""
var non_body_texture_2d_path := "" # not used if is_body
# UI data
var n_stars := -1
var n_planets := -1
var n_dwarf_planets := -1
var n_moons := -1
var n_asteroids := -1
var n_comets := -1
# camera
var view_rotate_when_close := false
var view_min_distance: float # camera normalizes for fov = 50
var view_position_zoom: Vector3
var view_position_45: Vector3
var view_position_top: Vector3

var spatial: Spatial # for camera parenting
var body: Body # = spatial if is_body else null

const PERSIST_AS_PROCEDURAL_OBJECT := true
const PERSIST_PROPERTIES := ["name", "selection_type", "classification",
	"is_body", "up_selection_name", "non_body_texture_2d_path", "n_stars", "n_planets", "n_dwarf_planets",
	"n_moons", "n_asteroids", "n_comets", "view_rotate_when_close", "view_min_distance",
	"view_position_zoom", "view_position_45", "view_position_top"]
const PERSIST_OBJ_PROPERTIES := ["spatial", "body"]

# read-only
var texture_2d: Texture
var texture_slice_2d: Texture # stars only
# private
var _global_time_array: Array = Global.time_array

func get_north() -> Vector3:
	if is_body:
		return body.north_pole
	return ECLIPTIC_NORTH

func get_orbit_anomaly_for_camera() -> float:
	# returns -INF as null value if not applicable
	if !is_body or !view_rotate_when_close:
		return -INF
	var orbit: Orbit = body.orbit
	if !orbit:
		return -INF
	return orbit.get_anomaly_for_camera(_global_time_array[0])

func init(selection_type_: int) -> void:
	selection_type = selection_type_
	match selection_type_:
		SelectionType.SELECTION_MOON:
			pass
		SelectionType.SELECTION_PLANET, SelectionType.SELECTION_DWARF_PLANET:
			n_moons = 0 # non -1 are valid for counting & UI display
		SelectionType.SELECTION_STAR, SelectionType.SELECTION_STAR_SYSTEM:
			n_planets = 0
			n_dwarf_planets = 0
			n_moons = 0
			n_asteroids = 0
			n_comets = 0
			continue
		SelectionType.SELECTION_STAR_SYSTEM:
			n_stars = 0

func change_count(change_selection_type: int, amount: int) -> void:
	match change_selection_type:
		SelectionType.SELECTION_MOON:
			if n_moons != -1:
				n_moons += amount
		SelectionType.SELECTION_PLANET:
			if n_planets != -1:
				n_planets += amount
		SelectionType.SELECTION_DWARF_PLANET:
			if n_dwarf_planets != -1:
				n_dwarf_planets += amount
		SelectionType.SELECTION_STAR:
			if n_stars != -1:
				n_stars += amount

func _init() -> void:
	_on_init()

func _on_init() -> void:
	Global.connect("system_tree_built_or_loaded", self, "_init_unpersisted")

func _init_unpersisted(_is_new_game: bool) -> void:
	if is_body:
		texture_2d = body.texture_2d
		texture_slice_2d = body.texture_slice_2d
	else:
		texture_2d = load(non_body_texture_2d_path)
