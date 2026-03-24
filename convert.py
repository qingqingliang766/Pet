import sys
from PIL import Image

def convert_webp_to_png(input_path, output_path):
    try:
        im = Image.open(input_path)
        im.save(output_path, "PNG")
        print(f"Successfully converted {input_path} to {output_path}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    convert_webp_to_png("pet.webp", "pet.png")
