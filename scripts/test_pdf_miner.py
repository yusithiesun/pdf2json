import importlib
import sys
import time
import re
 
importlib.reload(sys)
time1 = time.time()
# print("初始时间为：",time1)
 
from pdfminer.pdfparser import  PDFParser,PDFDocument
from pdfminer.pdfinterp import PDFResourceManager, PDFPageInterpreter
from pdfminer.converter import PDFPageAggregator
from pdfminer.layout import LTTextBoxHorizontal,LAParams,LTChar
from pdfminer.pdfinterp import PDFTextExtractionNotAllowed
 

 
def parse(pdf_path):
    '''解析PDF文本'''
    txt = ''
    pdf_content = []
    splited_content = []
    chapter_title = "概述"
    chapter = {'title':chapter_title,'content':[]}
    title_set = set()
    num_set = set()

    fp = open(pdf_path,'rb')
    #用文件对象创建一个PDF文档分析器
    parser = PDFParser(fp)
    #创建一个PDF文档
    doc = PDFDocument()
    #连接分析器，与文档对象
    parser.set_document(doc)
    doc.set_parser(parser)
 
    #提供初始化密码，如果没有密码，就创建一个空的字符串
    doc.initialize()
 
    #检测文档是否提供txt转换，不提供就忽略
    if not doc.is_extractable:
        raise PDFTextExtractionNotAllowed
    else:
        #创建PDF，资源管理器，来共享资源
        rsrcmgr = PDFResourceManager()
        #创建一个PDF设备对象
        laparams = LAParams()
        device = PDFPageAggregator(rsrcmgr,laparams=laparams)
        #创建一个PDF解释其对象
        interpreter = PDFPageInterpreter(rsrcmgr,device)
 
        #循环遍历列表，每次处理一个page内容
        # doc.get_pages() 获取page列表
        
        for page in doc.get_pages():
            
            interpreter.process_page(page)
            #接受该页面的LTPage对象
            page_layout = device.get_result()
            # 这里layout是一个LTPage对象 里面存放着 这个page解析出的各种对象
            # 一般包括LTTextBox, LTFigure, LTImage, LTTextBoxHorizontal 等等
            # 想要获取文本就获得对象的text属性，
            for element in page_layout:
                if(isinstance(element,LTTextBoxHorizontal)):
                    txt = txt + element.get_text().replace(' ','')
            txt_list = txt.split('\n')

    #划分章节
    pattern = re.compile(r'^[\(\[\u7B2C\uFF08\u3010]*[\d一二三四五六七八九十壹贰叁肆伍陆柒捌玖拾]{1,3}[\)\]\uFF09\u3011\.|、| ]+[\u4e00-\u9fa5]+')
    no_pattern = re.compile(r'.*[\u5E74|\u6708|\u65E5]+.*') #年月日
    #num_pattern = re.compile(r'[\d一二三四五六七八九十壹贰叁肆伍陆柒捌玖拾]+')
    for tl in txt_list:
        pattern_result = pattern.match(tl)
        #章节标题
        if pattern_result != None and len(tl)<30:
            no_pattern_result = no_pattern.match(pattern_result.group(0))
            if no_pattern_result == None:
                splited_content.append(chapter)
                #新建chapter
                chapter_title = pattern_result.group(0)
                chapter = {'title':chapter_title,'content':[]}
                if chapter_title in title_set:
                    #去除已出现过标题所在的章节
                    for items in splited_content:
                        if chapter_title in items:
                            del items[chapter_title]
                else:
                    title_set.add(chapter_title)   
            #章节内容
        else:
            chapter['content'].append(tl)
    splited_content.append(chapter)

    #清洗文本
    para = ''
    splited_content = list(filter(None,splited_content))
    for ch in splited_content:
        chapter = {'title':ch['title'],'content':[]}
        for line in ch['content']:
            #data table block
            if len(re.findall('\d', line))!=0 and len(re.findall('\d', line))/len(line) > 0.5:
                continue
            #no repeat of title
            elif len(re.findall('^[一二三四五六七八九十壹贰叁肆伍陆柒捌玖拾]',line)) > 0:
                continue
            elif len(re.findall('^资料来源',line)) > 0:
                continue
            #no sentence block
            elif len(re.findall('。|！|？|，|、',line)) == 0:
                continue
            else:
                if line.endswith('。'):
                    #末尾是结束标点的句子，视为段落结尾
                    para = para + line
                    chapter['content'].append(para) 
                    para = ''
                else:
                    para = para + line
        pdf_content.append(chapter)

    print(pdf_content)
    return pdf_content
                    
 
if __name__ == '__main__':
    parse(pdf_path = '/data2/private/wuyusi/data/pdf_data/xinguyanbao/east_money-xinguyanbao-1.pdf')
    time2 = time.time()
    print("总共消耗时间为:",time2-time1)