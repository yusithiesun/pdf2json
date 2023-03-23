from pdfminer.high_level import extract_pages
from pdfminer.layout import LTTextContainer

f = open('/Users/yusi/codes/thu/pdf2json/my_test/data/output/out.txt','a')

#li = list(extract_pages("/Users/yusi/codes/thu/pdf2json/my_test/data/xinguyanbao/east_money-xinguyanbao-6.pdf"))
for page_layout in extract_pages("/Users/yusi/codes/thu/pdf2json/my_test/data/xinguyanbao/east_money-xinguyanbao-6.pdf"):
    for element in page_layout:
        if isinstance(element, LTTextContainer):
            #f.write(element.get_text())
            print(element.get_text())