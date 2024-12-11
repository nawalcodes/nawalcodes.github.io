def get_bmp_dimensions(filepath):
    with open(filepath, 'rb') as bmp_file:
        bmp_file.seek(18)  # The width starts at byte 18 in the BMP file header
        width_bytes = bmp_file.read(4)
        height_bytes = bmp_file.read(4)
        
        # Convert bytes to integers (little-endian format)
        width = int.from_bytes(width_bytes, byteorder='little')
        height = int.from_bytes(height_bytes, byteorder='little')
        return width, height

# Example usage
bmp_filepath = 'coins.bmp'  # Replace with your BMP file path
width, height = get_bmp_dimensions(bmp_filepath)
print(f"Dimensions of the BMP file: {width}x{height}")
