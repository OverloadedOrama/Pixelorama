class_name TIFFLoader
extends RefCounted

# https://www.fileformat.info/format/tiff/egff.htm
# Based on: https://github.com/angel-01/image-to-scene
# Licensed under MIT


## MSB-first bit reader (TIFF uses big-endian bit order)
class BitReaderMSB:
	var data: PackedByteArray
	var bit_pos := 0  # bit index from start of stream

	func _init(d: PackedByteArray) -> void:
		data = d

	func read_bits(n: int) -> int:
		var result := 0
		for i in range(n):
			var byte_index := bit_pos >> 3
			if byte_index >= data.size():
				return -1  # EOF

			var bit_index := 7 - (bit_pos & 7)
			var bit := (data[byte_index] >> bit_index) & 1
			result = (result << 1) | bit
			bit_pos += 1
		return result


## Data for TIFF's Image File Directory.
class IFD:
	var new_offset: int
	var photometric_interpretation: int
	var compression: int
	var image_length: int
	var image_width: int
	var rows_per_strip: int
	var strip_offsets: PackedInt32Array
	var strip_byte_counts: PackedInt32Array
	var page_name: String
	var samples_per_pixel: int
	var predictor: int
	var data: PackedByteArray
	var image: Image


## Return a flattened [Image] from TIFF image path.
static func load_flattened_tiff_image(path: String) -> Image:
	var result := load_tiff(path)
	return flatten_tiff_layers(result)


## Flattens all layers to a single [Image].
static func flatten_tiff_layers(data: Array[IFD]) -> Image:
	var final_image: Image = null
	for i in data:
		var image := i.image

		if not final_image:
			final_image = Image.new()
			final_image.copy_from(image)
		else:
			final_image.blend_rect(
				image, Rect2(Vector2.ZERO, Vector2(i.image_width, i.image_length)), Vector2.ZERO
			)

	return final_image


## Returns TIFF image data parsed, as an array of [TiffLoader.IFD]s for each layer.
static func load_tiff(path: String) -> Array[IFD]:
	var f := FileAccess.open(path, FileAccess.READ)
	var header := "%x" % f.get_16()
	header = header.to_upper()
	if not header in ["4949", "4D4D"]:
		print("This image is not a TIFF one")
		return []
	f.big_endian = true if header == "4D4D" else false
	print(f.big_endian)

	f.get_16()
	var offset := f.get_32()
	f.seek(offset)
	var final_result: Array[IFD] = []
	while offset:
		var result := read_ifd(f, offset)
		if not is_instance_valid(result):
			return []
		final_result.append(result)
		offset = result.new_offset
		f.seek(offset)

	return final_result


## Main parser of TIFF file.
static func read_ifd(f: FileAccess, offset: int) -> IFD:
	if offset == 0:
		return null

	var number_of_directory_entries := f.get_16()
	var ifd := IFD.new()

	for i in range(0, number_of_directory_entries):
		var tag := f.get_16()
		var field_type := f.get_16()
		var number_of_values := f.get_32()
		var value_offset_bytes := f.get_buffer(4)
		if f.big_endian:
			value_offset_bytes.reverse()
		var value_offset := value_offset_bytes.decode_u32(0)
		match tag:
			277:
				ifd.samples_per_pixel = value_offset
			279:
				var current_position := f.get_position()
				if number_of_values == 1:
					ifd.strip_byte_counts.append(value_offset)
				else:
					f.seek(value_offset)
					for z in range(0, number_of_values):
						var strip_byte_count: int
						if field_type == 4:
							strip_byte_count = f.get_32()
						if field_type == 3:
							strip_byte_count = f.get_16()

						ifd.strip_byte_counts.append(strip_byte_count)

				f.seek(current_position)
			273:
				var current_position := f.get_position()
				if number_of_values == 1:
					ifd.strip_offsets.append(value_offset)
				else:
					f.seek(value_offset)
					for z in range(0, number_of_values):
						var strip_offset: int
						if field_type == 4:
							strip_offset = f.get_32()
						if field_type == 3:
							strip_offset = f.get_16()

						ifd.strip_offsets.append(strip_offset)

				f.seek(current_position)
			278:
				ifd.rows_per_strip = value_offset
			285:
				var current_position := f.get_position()
				f.seek(value_offset)
				ifd.page_name = ""
				for j in range(0, number_of_values):
					ifd.page_name += f.get_buffer(1).get_string_from_utf8()

				f.seek(current_position)
			262:
				ifd.photometric_interpretation = value_offset
			259:
				var values := read_tiff_value(f, field_type, number_of_values, value_offset)
				ifd.compression = values[0]
				prints(
					"Compression:",
					ifd.compression,
					field_type,
					number_of_values,
					value_offset_bytes
				)
				#if ifd.compression != 1:
				#print("TIFF image must be uncompressed")
				#continue
			257:
				ifd.image_length = value_offset
			256:
				ifd.image_width = value_offset
			317:
				ifd.predictor = value_offset

	var new_offset := f.get_32()
	var data: PackedByteArray
	for i in ifd.strip_offsets.size():
		if i >= ifd.strip_byte_counts.size():
			print("Invalid TIFF image.")
			return null
		f.seek(ifd.strip_offsets[i])
		var strip_byte := ifd.strip_byte_counts[i]
		var compressed := f.get_buffer(strip_byte)
		if ifd.compression == 5:  # LZW
			var strip_data := decompress_lzw(compressed)
			data.append_array(strip_data)
		else:
			# No compression (or other types)
			data.append_array(compressed)
	if ifd.predictor == 2:
		apply_horizontal_predictor(data, ifd.image_width, ifd.samples_per_pixel)
	ifd.data = data
	ifd.new_offset = new_offset

	var format: Image.Format

	if ifd.samples_per_pixel == 3:
		format = Image.FORMAT_RGB8
	if ifd.samples_per_pixel == 4:
		format = Image.FORMAT_RGBA8
	ifd.image = Image.create_from_data(ifd.image_width, ifd.image_length, false, format, ifd.data)
	if ifd.image.is_empty():
		print("Invalid TIFF image.")
		return null

	return ifd


static func read_tiff_value(
	f: FileAccess, field_type: int, count: int, value_offset: int
) -> PackedInt32Array:
	var type_size := 1
	match field_type:
		1, 2:
			type_size = 1  # BYTE, ASCII
		3:
			type_size = 2  # SHORT
		4:
			type_size = 4  # LONG
		5:
			type_size = 8  # RATIONAL

	var total_size := type_size * count

	# Inline?
	if total_size <= 4:
		# Decode from the value_offset integer itself
		var raw := PackedByteArray()
		raw.resize(4)
		raw.encode_u32(0, value_offset)

		if f.big_endian:
			raw.reverse()

		# Trim to actual size
		raw = raw.slice(0, total_size)

		# Parse into numbers
		return parse_values(raw, field_type, count)
	else:
		# Offset to data
		f.seek(value_offset)
		var raw := f.get_buffer(total_size)
		if f.big_endian:
			raw.reverse()
		return parse_values(raw, field_type, count)


static func parse_values(raw: PackedByteArray, field_type: int, count: int) -> PackedInt32Array:
	var values := PackedInt32Array()
	var index := 0
	for i in count:
		match field_type:
			3:  # SHORT
				values.append(raw.decode_u16(index))
				index += 2
			4:  # LONG
				values.append(raw.decode_u32(index))
				index += 4
			# add others as needed
	return values


static func decompress_lzw(data: PackedByteArray) -> PackedByteArray:
	var out := PackedByteArray()
	var reader := BitReaderMSB.new(data)

	# Initial dictionary: 0–255 literal bytes
	var dict: Array[PackedByteArray] = []
	dict.resize(4096)
	for i in range(256):
		dict[i] = PackedByteArray([i])

	var next_code := 258  # 256 & 257 are reserved in TIFF but unused
	var code_size := 9
	var code_max := 1 << code_size

	var prev: PackedByteArray = []

	while true:
		var code := reader.read_bits(code_size)
		if code < 0:
			break  # EOF

		var entry: PackedByteArray

		if code < next_code and not dict[code].is_empty():
			# Normal dictionary hit
			entry = dict[code]
		elif code == next_code and not prev.is_empty():
			# KwKwK special TIFF/GIF case
			entry = prev + PackedByteArray([prev[0]])
		else:
			# Truly invalid stream
			break

		# Output sequence
		out.append_array(entry)

		# Add new dictionary entry
		if not prev.is_empty():
			var new_entry := prev + PackedByteArray([entry[0]])
			dict[next_code] = new_entry
			next_code += 1

			# Grow code size at boundaries
			if next_code == code_max and code_size < 12:
				code_size += 1
				code_max = (1 << code_size)

		prev = entry

	return out


static func apply_horizontal_predictor(data: PackedByteArray, width: int, spp: int) -> void:
	var stride := width * spp
	var total := data.size()
	var offset := 0

	while offset < total:
		# If the strip ends with a partial row, clamp to avoid overflow.
		var row_end := mini(offset + stride, total)

		# Apply predictor for this row.
		# Start at the second pixel → skip the first spp bytes.
		for i in range(offset + spp, row_end):
			data[i] = (data[i] + data[i - spp]) & 0xFF
		offset += stride
