import json
from PIL import Image, ExifTags, ImageOps, ImageEnhance
from pytesseract import pytesseract
import enum
import re
from datetime import datetime

class OS(enum.Enum):
    Mac = 0
    Windows = 1

class FoodItem:
    def __init__(self, name=None, price=None, quantity=1):
        self.name = name
        self.price = price
        self.quantity = quantity

    def to_dict(self):
        return {
            'text1': self.name,
            'text2': f'${self.price:.2f}',
            'selectedNumber': self.quantity,
            'addedPersons': []
        }

class Receipt:
    def __init__(self, restaurant_name, items, subtotal, gratuity, tax, total, date):
        self.restaurant_name = restaurant_name
        self.items = items
        self.subtotal = subtotal
        self.gratuity = gratuity
        self.tax = tax
        self.total = total
        self.date = date

    def to_dict(self):
        return {
            'title': self.restaurant_name,
            'tip': str(self.gratuity),
            'tax': str(self.tax),
            'inputInfos': [item.to_dict() for item in self.items],
            'pickedContacts': [],
            'isPersonSelected': [],
            'saved': False
        }

class ImageReader:
    def __init__(self, os: OS):
        if os == OS.Mac:
            print("Running on a MAC")
        elif os == OS.Windows:
            windows_path = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
            pytesseract.tesseract_cmd = windows_path
            print("Running on a Windows")

    def correct_image_orientation(self, img: Image.Image) -> Image.Image:
        try:
            for orientation in ExifTags.TAGS.keys():
                if ExifTags.TAGS[orientation] == 'Orientation':
                    break
            exif = img._getexif()
            if exif is not None:
                orientation = exif.get(orientation, 1)
                if orientation == 3:
                    img = img.rotate(180, expand=True)
                elif orientation == 6:
                    img = img.rotate(270, expand=True)
                elif orientation == 8:
                    img = img.rotate(90, expand=True)
        except (AttributeError, KeyError, IndexError) as e:
            print(f"Error correcting image orientation: {e}")
        return img

    def preprocess_image_grayscale_threshold(self, img: Image.Image) -> Image.Image:
        try:
            gray = ImageOps.grayscale(img)
            threshold = 128
            binary = gray.point(lambda p: p > threshold and 255)
            return binary
        except Exception as e:
            print(f"Error in preprocessing image with grayscale and threshold: {e}")
            raise

    def preprocess_image_sharpen(self, img: Image.Image) -> Image.Image:
        try:
            gray = ImageOps.grayscale(img)
            enhancer = ImageEnhance.Sharpness(gray)
            sharp_img = enhancer.enhance(2.0)  # Increase sharpness
            return sharp_img
        except Exception as e:
            print(f"Error in preprocessing image with sharpening: {e}")
            raise

    def preprocess_image_brighten(self, img: Image.Image) -> Image.Image:
        try:
            enhancer = ImageEnhance.Brightness(img)
            bright_img = enhancer.enhance(1.5)  # Increase brightness
            return bright_img
        except Exception as e:
            print(f"Error in preprocessing image with brightening: {e}")
            raise

    def extract_text(self, image_path: str, lang: str) -> str:
        try:
            img = Image.open(image_path)
            img = self.correct_image_orientation(img)

            # No preprocessing
            text_no_preprocess = pytesseract.image_to_string(img, lang=lang)

            # Grayscale and thresholding
            preprocessed_img1 = self.preprocess_image_grayscale_threshold(img)
            text_grayscale_threshold = pytesseract.image_to_string(preprocessed_img1, lang=lang)

            # Grayscale and sharpening
            preprocessed_img2 = self.preprocess_image_sharpen(img)
            text_grayscale_sharpen = pytesseract.image_to_string(preprocessed_img2, lang=lang)

            # Brightening
            preprocessed_img3 = self.preprocess_image_brighten(img)
            text_brighten = pytesseract.image_to_string(preprocessed_img3, lang=lang)

            return text_no_preprocess, text_grayscale_threshold, text_grayscale_sharpen, text_brighten
        except Exception as e:
            print(f"Error in extracting text: {e}")
            raise

    def parse_receipt(self, text: str) -> Receipt:
        try:
            lines = text.split('\n')
            restaurant_name = ""
            for line in lines:
                if line.strip() and "Order Number" not in line:
                    restaurant_name = line.strip()
                    break

            item_pattern = re.compile(r'(\d+)?\s*(.*?)\s*\$?(\d+\.\d{2})')
            subtotal_pattern = re.compile(r'Subtotal\s*\$?(\d+\.\d{2})')
            tax_pattern = re.compile(r'Tax\s*\$?(\d+\.\d{2})')
            gratuity_pattern = re.compile(r'Gratuity\s*\(\s*(\d+\.\d{2})%?\s*\)')
            total_pattern = re.compile(r'Total\s*\$?(\d+\.\d{2})')
            date_pattern = re.compile(r'Ordered:\s*(\d{1,2}/\d{1,2}/\d{2,4}\s\d{1,2}:\d{2}\s(?:AM|PM))')
            date_fallback_pattern = re.compile(r'(\d{1,2}/\d{1,2}/\d{2,4}\s\d{1,2}:\d{2}:\d{2}\s(?:AM|PM))')

            items = []
            subtotal = gratuity = tax = total = date = None
            current_item_name = current_item_price = None

            for line in lines:
                line = line.strip()

                # Check if the line is a standalone price
                if re.match(r'^\$?(\d+\.\d{2})$', line):
                    if current_item_name:
                        current_item_price = float(line.replace('$', ''))
                        items.append(FoodItem(current_item_name, current_item_price))
                        current_item_name = current_item_price = None
                    continue

                # Match item pattern
                item_match = item_pattern.match(line)
                if item_match:
                    quantity = item_match.group(1)
                    quantity = int(quantity) if quantity else 1
                    name = item_match.group(2).strip() if item_match.group(2) else None
                    price = item_match.group(3)
                    price = float(price) if price else None

                    if name and price:
                        items.append(FoodItem(name, price, quantity))
                    elif name:
                        current_item_name = name
                    continue

                # Match subtotal
                subtotal_match = subtotal_pattern.search(line)
                if subtotal_match:
                    subtotal = float(subtotal_match.group(1))

                # Match gratuity
                gratuity_match = gratuity_pattern.search(line)
                if gratuity_match:
                    gratuity = float(gratuity_match.group(1))

                # Match tax
                tax_match = tax_pattern.search(line)
                if tax_match:
                    tax = float(tax_match.group(1))

                # Match total
                total_match = total_pattern.search(line)
                if total_match:
                    total = float(total_match.group(1))

                # Match date
                date_match = date_pattern.search(line)
                if date_match:
                    date_str = date_match.group(1)
                    date = datetime.strptime(date_str, '%m/%d/%y %I:%M %p')
                else:
                    date_fallback_match = date_fallback_pattern.search(line)
                    if date_fallback_match:
                        date_str = date_fallback_match.group(1)
                        date = datetime.strptime(date_str, '%m/%d/%Y %I:%M:%S %p')

            return Receipt(restaurant_name, items, subtotal, gratuity, tax, total, date)
        except Exception as e:
            print(f"Error in parsing receipt: {e}")
            raise

if __name__ == '__main__':
    # Read the file path from the text file
    with open('/path/to/document/directory/image_path.txt', 'r') as file:
        image_path = file.read().strip()

    ir = ImageReader(OS.Mac)
    text = ir.extract_text(image_path, lang='eng')
    receipt = ir.parse_receipt(text)
    receipt_json = json.dumps(receipt.to_dict())

    # Save the JSON data to a file
    with open('/path/to/document/directory/receipt.json', 'w') as json_file:
        json_file.write(receipt_json)
