#!usr/bin/python
# -*- coding: utf-8 -*-
import importlib
import sys
import re
import json
import operator
 
importlib.reload(sys)

from pdfminer.pdfparser import  PDFParser,PDFDocument,PDFPasswordIncorrect,PSEOF,PDFSyntaxError,PDFEncryptionError
from pdfminer.pdfinterp import PDFResourceManager, PDFPageInterpreter,PDFTextExtractionNotAllowed
from pdfminer.converter import PDFPageAggregator
from pdfminer.layout import LTTextBoxHorizontal,LAParams,LTText
from pdfminer.pdfinterp import PDFTextExtractionNotAllowed
 

def parsing_content(src,id):
    pdf_path = '/data2/private/wuyusi/data/pdf_data/'+src+'/'+id+'.pdf'
    textline_li = []
    content_data = []
    txt = ''
    FOUND_INDEX = False
    fp = open(pdf_path,'rb')
    #用文件对象创建一个PDF文档分析器
    parser = PDFParser(fp)
    #创建一个PDF文档
    doc = PDFDocument()
    #连接分析器，与文档对象
    parser.set_document(doc)
    try:
        doc.set_parser(parser)
    except PSEOF or PDFSyntaxError:
        return []
 
    #提供初始化密码，如果没有密码，就创建一个空的字符串
    try:
        doc.initialize()
    except PDFPasswordIncorrect or PDFTextExtractionNotAllowed or PSEOF or PDFSyntaxError or PDFEncryptionError:
        return []
 
    #检测文档是否提供txt转换，不提供就忽略
    if not doc.is_extractable:
        #raise PDFTextExtractionNotAllowed
        return []
    else:
        #创建PDF，资源管理器，来共享资源
        rsrcmgr = PDFResourceManager()
        #创建一个PDF设备对象
        laparams = LAParams()
        device = PDFPageAggregator(rsrcmgr,laparams=laparams)
        #创建一个PDF解释其对象
        interpreter = PDFPageInterpreter(rsrcmgr,device)
        
        ch = ''
 
        #循环遍历列表，每次处理一个page内容
        # doc.get_pages() 获取page列表
        
        for page in doc.get_pages():
            
            interpreter.process_page(page)
            #接受该页面的LTPage对象
            page_layout = device.get_result()
            # 这里layout是一个LTPage对象 里面存放着 这个page解析出的各种对象
            # 一般包括LTTextBox, LTFigure, LTImage, LTTextBoxHorizontal 等等
            # 想要获取文本就获得对象的text属性
            for element in page_layout:
                if(isinstance(element,LTTextBoxHorizontal)):
                    for textline in element:
                        textline_li.append(textline)

    fp.close()

    for textline in textline_li:
           #文件中显式包含目录
        tl = re.sub(r'\[.+\]','',textline.get_text())
        #divide chapter
        if len(tl.replace('\n','')) <= 1 and len(ch) > 1 :
            if len(re.findall(r'\u76EE.*\u5F55',ch))>0: #找到目录所在章节
                index_li = parsing_index(ch)
                FOUND_INDEX = True
                break
            else:
                ch = ""
        else:
            ch = ch + tl

    if FOUND_INDEX == True and len(index_li) > 0:
        chapters = indexing(textline_li,index_li)
        if chapters[0]['content'] == -1: #索引失效
            chapters = []
    else:
        chapters = chaptering(textline_li)

    content_data = []
    if chapters != []:
        for ch in chapters:
            x0,x1,w,blank = framing(ch['content'])
            content_data = content_data + paragraphing(ch,x0,x1,w,blank)
    else:
        #content_data.append('#概述')
        for index in index_li:
            content_data.append('#'+index)
        
        chapters = chaptering(textline_li)
        for ch in chapters:
            x0,x1,w,blank = framing(ch['content'])
            content_data = content_data + paragraphing(ch,x0,x1,w,blank)

    result_content = []
    text_pattern = re.compile(r'[\u4e00-\u9fa5]')
    for i,ct in enumerate(content_data):
        if i < len(content_data) - 1:
            if content_data[i+1][0] == '#':
                next_line_para = False
            else:
                next_line_para = True
        else: # 最后一行
            next_line_para = False

        if ct[0] == '#' and ct[1] == '#': #小标题或存疑项
            txt_num = len(re.findall(text_pattern,ct))
            txt_rate = txt_num/len(ct)
            if txt_rate > 0.6 and next_line_para:
                result_content.append(ct)

        elif ct[0] == '#' and ct[1] != '#': #章节标题
            txt_num = len(re.findall(text_pattern,ct))
            txt_rate = txt_num/len(ct.replace('#',''))
            if txt_rate > 0.7:
                result_content.append(ct)

        elif len(ct) > 3 and (ct.endswith('。') or ct.endswith('？') or ct.endswith('；') or ct.endswith('！') \
            or ct.endswith('?') or ct.endswith('!') or ct.endswith(';')):
            #末尾是结束标点的句子，视为段落结尾，视为段落有效
            result_content.append(ct) 

    return result_content

def parsing_index(s):
    '''将目录所在element文本拼接而成的字符串解析成为目录列表'''
    index_list = []
    index_li = s.split('\n')
    title_set = set()
    pattern = re.compile(r'^[\(\[\u7B2C\uFF08\u3010]*(([1-9一二三四五六七八九十壹贰叁肆伍陆柒捌玖拾]{1})\.?)+[\)\]\uFF09\u3011|、| ]+.*[\u4e00-\u9fa5]$')
    digit_pattern = re.compile(r'^[\d\.]+[ ]*\D*[\u4e00-\u9fa5，。！？：:]+')
    num = 1
    up = 5

    for i in index_li:
        if len(i) > 0:
            if i[0] != '图' and i!=('' or ' ' or '\n') and i[0] != '表':
                if len(i) < up:
                            up = len(i)
                if pattern.match(i) != None and pattern.match(i).group(0)[:up] not in title_set and len(re.findall('。|！|？|，|；|年|月|日|元|\%|0',i)) == 0:        
                    index_list.append(pattern.match(i).group(0))
                    l = len(pattern.match(i).group(0))
                    title_set.add(pattern.match(i).group(0)[:5])
                elif len(re.sub(r'[\.]*[ ]+[\d]{1,3}','',i)) < len(i) and re.match(r'^[1-9]{1}[\.]{1}',i) != None:   
                    if int(re.match(r'^[1-9]{1}',i).group(0)) == num + 1 or int(re.match(r'^[1-9]{1}',i).group(0)) == num:
                        num = int(re.match(r'^[1-9]{1}',i).group(0))
                        if i[:up] not in title_set:
                            index_list.append(re.sub(r'[\.]*[ ]+[\d]{1,3}','',i).replace(' ',''))
                            title_set.add(i[:up])
                up = 5
                    
    return index_list

def chaptering(textline_li):
    '''根据段落特征划分章节 返回[{'title':'标题'},'content':[textline对象1,textline对象2...]]'''
    #title_pattern_str = ''
    splited_content = []
    title_set = set()
    chapter_title = "概述"
    chapter = {'title':chapter_title,'content':[]}
    pattern = re.compile(r'^[\(\[\u7B2C\uFF08\u3010]*[\d一二三四五六七八九十壹贰叁肆伍陆柒捌玖拾]{1,2}[\)\]\uFF09\u3011\.|、| ]+[\u4e00-\u9fa5]+')
    no_pattern = re.compile(r'.*[\u5E74|\u6708|\u65E5|英寸|资料来源]+.*') #年月日
    #num_pattern = re.compile(r'[\d一二三四五六七八九十壹贰叁肆伍陆柒捌玖拾]+')
    for tl in textline_li:
        pattern_result = pattern.match(tl.get_text())
        #章节标题
        if pattern_result != None:
            if len(tl.get_text())<30:
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
                        #title_pattern_str += tl.get_text().replace('/n','').replace(' ','')\
                            #.replace('[','\[').replace(']','\]').replace('(','\(').replace(')','\)')\
                                #+'|'   
            else:
                chapter['content'].append(tl)
            #章节内容
        else:
            chapter['content'].append(tl)
            
    splited_content.append(chapter)

    chapters = []
    for ch in splited_content:
        chapter = {'title':ch['title'],'content':[]}
        for tl in ch['content']:
            txt = tl.get_text().replace('/n','').replace(' ','').replace('.','')
            txt_rate = len(txt) / len(tl.get_text())
            if txt_rate > 0.4:
                chapter['content'].append(tl)
        chapters.append(chapter)
 
    return chapters 

def indexing(textline_li,index_li):
    '''根据目录划分章节，返回[{'title':'标题'},'content':[textline对象1,textline对象2...]]'''
    
    i = 0 
    j = 0
    chapters = []
    #title_pattern_str = ''
    index_pattern = re.compile(r'[0-9]$')
    chapter = {
        'title':'概述',
        'content':[]
    }

    while i < len(textline_li) and j < len(index_li):
        #print(textline_li[i].get_text().replace(' ','').replace('\n',''))
        #print(index_li[j])
        if index_li[j].find(textline_li[i].get_text().replace(' ','').replace('\n','')) != -1 \
            and len(textline_li[i].get_text().replace(' ','').replace('\n',''))/len(index_li[j]) > 0.6: #章节标题
            #print(textline_li[i].get_text().replace(' ','').replace('\n',''))
            chapters.append(chapter)
            chapter = {
                    'title':index_li[j],
                    'content':[]
                }
            #title_pattern_str += index_li[j] + '|'
            j = j + 1   
             # 寻找下一章节
        else: #章节内容
            chapter['content'].append(textline_li[i])
        
        i = i + 1

    if len(chapters) < len(index_li) + 1:
        chapters = []
        chapters.append({'title':'概述','content':-1})
        chapters.append({'title':'正文','content':textline_li})
        #title_pattern_str = ''

    return chapters


def framing(textline_li):
    '''统计文字块宽度、正文左右边界横坐标、段内行间距'''
    x0,x1,w,blank,y0 = 0,0,0,0,0
    width_dict = {}
    TOUCH_BOUNDARY = False
    
    for tl in textline_li: #宽度统计
        if len(re.findall('。|！|？|，|、|；',tl.get_text())) > 0:
            if str(10*int(int(tl.width)/10)) not in width_dict:
                width_dict[str(10*int(int(tl.width)/10))] = 1
            else:
                width_dict[str(10*int(int(tl.width)/10))] = width_dict[str(10*int(int(tl.width)/10))] + 1
    try:
        top1_w = int(sorted(width_dict.items(),key=operator.itemgetter(1),reverse=True)[0][0])
        top2_w = int(sorted(width_dict.items(),key=operator.itemgetter(1),reverse=True)[1][0])
    except IndexError:
        return 0,0,0,0
    if top2_w > top1_w :
        w = top2_w
    else:
        w = top1_w
    
    for tl in textline_li: #左右边界统计
        if 10*int(int(tl.width)/10) == w: #顶格
            x0 = tl.x0 - 20 #左边界横坐标
            x1 = tl.x1 + 10  #右边界横坐标
            if TOUCH_BOUNDARY == True: #连续两行顶格
                blank = y0 - tl.y1 #段内行间距
                break
            else: #单行顶格
                TOUCH_BOUNDARY = True 
                y0 = tl.y0
        else:
            TOUCH_BOUNDARY = False #不顶格

    return x0,x1,w,blank

def paragraphing(chapter,x0,x1,w,blank ):
    '''章节内部分段'''
    paragraphed_content = ['#'+chapter['title']]
    para = ''

    #用页面布局筛选
    framed_chapters = []
    for tl in chapter['content']:
        if tl.x0 >= x0 - 20 and tl.x1 <= x1 + 20:
            framed_chapters.append(tl)

    for i,tl in enumerate(framed_chapters):
        # 在本章节正文栏内部
        
            try:
                txt = tl.get_text().replace('\n','').replace(' ','')

                end_with_ending_char = txt.endswith('。') or txt.endswith('：') or txt.endswith('？') or txt.endswith('！') or txt.endswith(':') or txt.endswith('?') or txt.endswith('!')
                indentation = abs(framed_chapters[i+1].x0 - tl.x0)>10
                more_distance_between_lines = abs(framed_chapters[i+1].y1 - tl.y0) > blank
                short_line = tl.width < framed_chapters[i-1].width - 30

                # 段落结尾（段落分界）
                if end_with_ending_char and \
                    (short_line or indentation or more_distance_between_lines) and len(re.findall('\.',txt)) < 4: 
                    if txt.endswith('：') or txt.endswith(':'):
                        para = para + txt.replace('\n','').replace(' ','')
                    else:
                        para += txt.replace('\n','').replace(' ','')
                    if len(para) > 0:
                        paragraphed_content.append(para)
                    para = ''
                
                # 段中
                else:
                    # 可疑行
                    if len(re.findall('。|！|？|，|、|；',txt)) == 0:
                        # 表格、段内信息栏
                        if (len(re.findall('\d', txt))!=0 and len(re.findall('\d', txt))/len(txt) > 0.5) \
                            or len(re.findall(':|：',txt)) != 0:
                            continue
                        # 页眉、侧边信息栏
                        if more_distance_between_lines \
                            or abs(tl.x0 - x0) > 50:
                            continue
                        # 链接、图注、表注
                        if len(re.findall('http',txt)) > 0 \
                            or len(re.findall('^图|^表|^资料来源',txt)) > 0:
                            #or len(re.findall(title_pattern_str[:-1],txt)) > 0:
                            continue
                        # 小标题
                        else:
                            if len(para) > 0:
                                paragraphed_content.append(para)
                            if len(txt.replace('\n','').replace(' ','')) > 0 and len(re.findall('\.',txt)) < 4:
                                paragraphed_content.append('##' + txt.replace('/n','').replace(' ',''))
                            para = ''
                    else:
                        # 正文:有句子结束符
                        if len(re.findall('^图|^表|^资料来源|来源',txt)) <= 0 and len(re.findall('\.',txt)) < 4 and len(txt) >= 3:
                            para += txt.replace('\n','').replace(' ','')
            except IndexError: # 本章的最后一句
                if w == 0:
                    break
                if len(re.findall('。|！|？|，|、',txt)) > 0:
                    para = para + txt.replace('\n','').replace(' ','')
    
    # 用文本规律筛选
    if len(paragraphed_content) == 1:
        para = ''
        for tl in chapter['content']:
            line = tl.get_text().replace('\n','').replace(' ','')
            #data table block
            if len(re.findall('\d', line))!=0 and len(re.findall('\d', line))/len(line) > 0.5:
                continue
            elif len(re.findall('^[资料来源｜来源]',line)) > 0:
                continue
            #no sentence block
            elif len(re.findall('。|！|？|，|、',line)) == 0:
                continue
            else:
                if line.endswith('。'):
                    #末尾是结束标点的句子，视为段落结尾
                    para = para + line
                    paragraphed_content.append(para) 
                    para = ''
                else:
                    para = para + line

    if para != '' and len(re.findall('^[资料来源｜来源]',para)) == 0:
        paragraphed_content.append(para) # 本章的最后一段
    
    return paragraphed_content


if __name__ == "__main__":
    '''
    src = sys.argv[1] # type of report
    pos_start = int(sys.argv[2]) # processing start position signal
    pos_end = int(sys.argv[3]) # processing end position signal
    
    '''
    src = 'xinguyanbao'
    pos_start = 6
    pos_end = 20

    src_f = open("/data2/private/wuyusi/data/eastmoney_report_data/"+src+".json",'r')
    target_f = open("/data2/private/wuyusi/data/processed-eastmoney_report_data/"+src+".json",'a')
    
    json_stream = src_f.readlines()
    for i,jsondata in enumerate(json_stream[pos_start:pos_end+1]):
        print(src+': '+str(i+pos_start))
        raw_data = json.loads(jsondata)
        
        processed_data = {
                "id":raw_data['id'],
                "meta":raw_data['meta'],
                "short_content" :raw_data['content'], # content from source html page
                "content": []
            }
        try:
            processed_data['content'] = parsing_content(src,raw_data['id']) #content from pdf parsing
            #print(processed_data)
            if processed_data['content'] != []:
                target_f.write(json.dumps(processed_data,ensure_ascii=False)+'\n')
        except KeyError:
            continue