import json
import os
import io
import langdetect
import fitz

def extract_pdf_info(pdf_file):
    # Open the PDF file
    with open(pdf_file, 'rb') as f:
        # Read the PDF file into memory
        pdf_data = io.BytesIO(f.read())

    # Load the PDF document using PyMuPDF
    doc = fitz.open(pdf_data)

    # Initialize the output dictionary
    output = {}

    # Loop over each page in the document
    for i in range(doc.page_count):
        # Get the text of the page
        page = doc.load_page(i)
        text = page.get_text()

        # Detect the language of the text
        lang = langdetect.detect(text)

        # Determine the title and content based on the language
        if lang == 'zh_cn':
            # For Chinese text, the first line is the title
            title = text.split('\n')[0]
            # The remaining text is the content
            content = '\n'.join(text.split('\n')[1:])
        else:
            # For English text, the title is the first sentence
            title = text.split('.')[0] + '.'
            # The remaining text is the content
            content = ' '.join(text.split('.')[1:])

        # Add the title and content to the output dictionary
        output[f'page_{i+1}'] = {'title': title.strip(), 'content': content.strip()}

    # Close the PDF document
    doc.close()

    # Return the output dictionary as JSON
    return json.dumps(output)


pdf_file = 'example.pdf'
pdf_info = extract_pdf_info(pdf_file)
print(pdf_info)
