import importlib
from inspect import stack
import sys
import re
import json
import operator

importlib.reload(sys)

from pdfminer.pdfparser import PDFParser
from pdfminer.pdfpage import PDFPage
from pdfminer.pdfdocument import PDFDocument
from pdfminer.pdfinterp import PDFResourceManager, PDFPageInterpreter
from pdfminer.converter import PDFPageAggregator
from pdfminer.layout import LTTextBoxHorizontal, LAParams, LTChar

# from pdfminer.pdfinterp import PDFTextExtractionNotAllowed


def parsing_content(pdf_path):
    # pdf_path = '/data2/private/wuyusi/data/pdf_data/'+src+'/'+id+'.pdf'
    textline_li = []
    content_data = []
    txt = ""
    fp = open(pdf_path, "rb")
    # 用文件对象创建一个PDF文档分析器
    parser = PDFParser(fp)
    # 创建一个PDF文档
    doc = PDFDocument(parser)
    # 连接分析器，与文档对象
    parser.set_document(doc)
    # doc.set_parser(parser)

    # 提供初始化密码，如果没有密码，就创建一个空的字符串
    # doc.initialize()

    # 检测文档是否提供txt转换，不提供就忽略
    if not doc.is_extractable:
        raise
    else:
        # 创建PDF，资源管理器，来共享资源
        rsrcmgr = PDFResourceManager()
        # 创建一个PDF设备对象
        laparams = LAParams()
        device = PDFPageAggregator(rsrcmgr, laparams=laparams)
        # 创建一个PDF解释其对象
        interpreter = PDFPageInterpreter(rsrcmgr, device)
        FOUND_INDEX = False
        ch = ""

        # 循环遍历列表，每次处理一个page内容
        # doc.get_pages() 获取page列表

        for i, page in enumerate(PDFPage.create_pages(doc)):
            # for page in doc.get_pages():
            interpreter.process_page(page)
            # 接受该页面的LTPage对象
            page_layout = device.get_result()
            # 这里layout是一个LTPage对象 里面存放着 这个page解析出的各种对象
            # 一般包括LTTextBox, LTFigure, LTImage, LTTextBoxHorizontal 等等
            # 想要获取文本就获得对象的text属性
            for element in page_layout:
                if isinstance(element, LTTextBoxHorizontal):
                    for textline in element:
                        textline_li.append(textline)

    for textline in textline_li:
        # 文件中显式包含目录
        tl = re.sub(r"\[.+\]", "", textline.get_text())
        # divide chapter
        if len(tl.replace("\n", "")) <= 1 and len(ch) > 1:
            if len(re.findall(r"\u76EE.*\u5F55", ch)) > 0:  # 找到目录所在章节
                index_li = parsing_index(ch)
                FOUND_INDEX = True
                break
            else:
                ch = ""
        else:
            ch = ch + tl

    fp.close()
    if FOUND_INDEX == True:
        chapters, title_pattern_str = indexing(textline_li, index_li)
        if chapters == []:
            chapters, title_pattern_str = chaptering(textline_li)
    else:
        chapters, title_pattern_str = chaptering(textline_li)

    for ch in chapters:
        x0, x1, w, blank = framing(ch["content"])
        chapter = paragraphing(ch, x0, x1, w, blank, title_pattern_str)
        content_data.append(chapter)

    return content_data


def parsing_index(s):
    # 将目录所在element文本拼接而成的字符串解析成为目录列表
    index_list = []
    index_li = s.split("\n")
    title_set = set()
    pattern = re.compile(
        r"^[\(\[\u7B2C\uFF08\u3010]*(([1-9一二三四五六七八九十壹贰叁肆伍陆柒捌玖拾]{1})\.?)+[\)\]\uFF09\u3011|、| ]+.*[\u4e00-\u9fa5]$"
    )
    digit_pattern = re.compile(r"^[\d\.]+[ ]*\D*[\u4e00-\u9fa5]+")
    num_pattern = re.compile(r"[\d一二三四五六七八九十壹贰叁肆伍陆柒捌玖拾]+")
    for i in index_li:
        if len(i) > 0:
            if i[0] != "图" and i != ("" or " " or "\n") and i[0] != "表":
                if (
                    pattern.match(i) != None
                    and pattern.match(i).group(0) not in title_set
                    and len(re.findall("。|！|？|，|；|年|月|日|元|\%|0", i)) == 0
                ):
                    index_list.append(pattern.match(i).group(0))
                    l = len(pattern.match(i).group(0))
                    title_set.add(pattern.match(i).group(0))
                elif (
                    digit_pattern.match(i) != None
                    and digit_pattern.match(i).group(0) not in title_set
                    and len(re.findall("。|！|？|，|；|年|月|日|元|\%|0", i)) == 0
                ):
                    index_list.append(digit_pattern.match(i).group(0))
                    title_set.add(digit_pattern.match(i).group(0))

    return index_list


def chaptering(textline_li):
    # 划分章节
    title_pattern_str = ""
    splited_content = []
    title_set = set()
    chapters = []
    ch = {}
    ch["title"] = "overview"
    ch["content"] = []

    para = {}
    para["title"] = ""
    para["content"] = []
    s = ""

    # end_pattern = re.compile(r'^[\.|\?|\!]')
    title_pattern = re.compile(r"^[0-9] [A-Z]")
    sub_title_pattern = re.compile(r"^[0-9]\.[0-9] [A-Z]")

    for tl in textline_li:
        txt = tl.get_text().replace("\n", "")
        if title_pattern.match(txt) and txt not in title_set:  # find chapter title
            ch["content"].append(para)
            chapters.append(ch)
            ch = {}
            ch["title"] = txt
            ch["content"] = []
            title_set.add(txt)
        else:  # chapter content
            if sub_title_pattern.match(txt) and txt not in title_set:  # 二级标题
                ch["content"].append(para)
                para = {}
                para["title"] = txt
                para["content"] = []
                title_set.add(txt)

            if txt.endswith("."):  # 一句话结束
                para["content"].append(s)
                s = ""

            else:
                s = s + txt

    ch["content"].append(para)

    return chapters, title_pattern_str


def indexing(textline_li, index_li):
    title_pattern_str = ""
    chapters = []
    pos = 0
    chapter = {"title": "概述", "content": []}
    for tl in textline_li:
        # 找到章节标题
        if tl.get_text().replace("\n", "").replace(" ", "") == index_li[pos]:
            chapters.append(chapter)
            chapter = {"title": index_li[pos], "content": []}
            title_pattern_str += (
                tl.get_text()
                .replace("/n", "")
                .replace(" ", "")
                .replace("[", "\[")
                .replace("]", "\]")
                .replace("(", "\(")
                .replace(")", "\)")
                + "|"
            )
            if pos < len(index_li) - 1:
                pos = pos + 1
        else:
            if len(re.findall("^图|^表|^资料来源|^http|\.\.\.\.", tl.get_text())) == 0:
                chapter["content"].append(tl)

    return chapters, title_pattern_str


def framing(textline_li):
    # 统计文字块宽度、正文左右边界横坐标、段内行间距
    x0, x1, w, blank, y0 = 0, 0, 0, 0, 0
    width_dict = {}
    TOUCH_BOUNDARY = False

    for tl in textline_li:  # 宽度统计
        if len(re.findall("。|！|？|，|、|；", tl.get_text())) > 0:
            if str(10 * int(int(tl.width) / 10)) not in width_dict:
                width_dict[str(10 * int(int(tl.width) / 10))] = 1
            else:
                width_dict[str(10 * int(int(tl.width) / 10))] = (
                    width_dict[str(10 * int(int(tl.width) / 10))] + 1
                )
    try:
        top1_w = int(
            sorted(width_dict.items(), key=operator.itemgetter(1), reverse=True)[0][0]
        )
        top2_w = int(
            sorted(width_dict.items(), key=operator.itemgetter(1), reverse=True)[1][0]
        )
    except IndexError:
        return 0, 0, 0, 0
    if top2_w > top1_w:
        w = top2_w
    else:
        w = top1_w

    for tl in textline_li:  # 左右边界统计
        if 10 * int(int(tl.width) / 10) == w:  # 顶格
            x0 = tl.x0 - 20  # 左边界横坐标
            x1 = tl.x1 + 10  # 右边界横坐标
            if TOUCH_BOUNDARY == True:  # 连续两行顶格
                blank = y0 - tl.y1  # 段内行间距
                break
            else:  # 单行顶格
                TOUCH_BOUNDARY = True
                y0 = tl.y0
        else:
            TOUCH_BOUNDARY = False  # 不顶格

    return x0, x1, w, blank


def paragraphing(chapter, x0, x1, w, blank, title_pattern_str):
    # 章节内部分段
    paragraphed_chapter = {
        "title": chapter["title"],
        "content": [],  # every element in this list is a string
    }
    para = ""

    # 用页面布局筛选
    framed_chapters = []
    for tl in chapter["content"]:
        if tl.x0 >= x0 - 20 and tl.x1 <= x1 + 20:
            framed_chapters.append(tl)

    for i, tl in enumerate(framed_chapters):
        # 在本章节正文栏内部

        try:
            txt = tl.get_text().replace("\n", "").replace(" ", "")

            end_with_ending_char = (
                txt.endswith("。")
                or txt.endswith("：")
                or txt.endswith("？")
                or txt.endswith("！")
                or txt.endswith(":")
                or txt.endswith("?")
                or txt.endswith("!")
            )
            indentation = abs(framed_chapters[i + 1].x0 - tl.x0) > 10
            more_distance_between_lines = abs(framed_chapters[i + 1].y1 - tl.y0) > blank
            short_line = tl.width < framed_chapters[i - 1].width - 30

            # 段落结尾（段落分界）
            if (
                end_with_ending_char
                and (short_line or indentation or more_distance_between_lines)
                and len(re.findall("\.", txt)) < 4
            ):
                para += txt.replace("\n", "").replace(" ", "")
                if len(para) > 0:
                    paragraphed_chapter["content"].append(para)
                para = ""

            # 段中
            else:
                # 可疑行
                if len(re.findall("。|！|？|，|、|；", txt)) == 0:
                    # 表格、段内信息栏
                    if (
                        len(re.findall("\d", txt)) != 0
                        and len(re.findall("\d", txt)) / len(txt) > 0.5
                    ) or len(re.findall(":|：", txt)) != 0:
                        continue
                    # 页眉、侧边信息栏
                    if more_distance_between_lines or abs(tl.x0 - x0) > 50:
                        continue
                    # 链接、图注、表注
                    if (
                        len(re.findall("http", txt)) > 0
                        or len(re.findall("^[图|表|资料来源]", txt)) > 0
                        or len(re.findall(title_pattern_str[:-1], txt)) > 0
                    ):
                        continue
                    # 小标题
                    else:
                        if len(para) > 0:
                            paragraphed_chapter["content"].append(para)
                        if (
                            len(txt.replace("\n", "").replace(" ", "")) > 0
                            and len(re.findall("\.", txt)) < 4
                        ):
                            paragraphed_chapter["content"].append(
                                txt.replace("/n", "").replace(" ", "")
                            )
                        para = ""
                else:
                    # 正文:有句子结束符
                    if (
                        len(re.findall("^[图|表|资料来源]", txt)) <= 0
                        and len(re.findall("\.", txt)) < 4
                        and len(txt) >= 3
                    ):
                        para += txt.replace("\n", "").replace(" ", "")
        except IndexError:  # 本章的最后一句
            if w == 0:
                break
            if len(re.findall("。|！|？|，|、", txt)) > 0:
                para = para + txt.replace("\n", "").replace(" ", "")
            if para != "":
                paragraphed_chapter["content"].append(para)  # 本章的最后一段

    # 用文本规律筛选
    if paragraphed_chapter["content"] == []:
        paragraphed_chapter = {
            "title": chapter["title"],
            "content": [],  # every element in this list is a string
        }
        para = ""
        for tl in chapter["content"]:
            line = tl.get_text().replace("\n", "").replace(" ", "")
            # data table block
            if (
                len(re.findall("\d", line)) != 0
                and len(re.findall("\d", line)) / len(line) > 0.5
            ):
                continue
            # no repeat of title
            elif len(re.findall(title_pattern_str[:-1], line)) > 0:
                continue
            elif len(re.findall("^[资料来源]", line)) > 0:
                continue
            # no sentence block
            elif len(re.findall("。|！|？|，|、", line)) == 0:
                continue
            else:
                if line.endswith("。"):
                    # 末尾是结束标点的句子，视为段落结尾
                    para = para + line
                    paragraphed_chapter["content"].append(para)
                    para = ""
                else:
                    para = para + line

    return paragraphed_chapter


if __name__ == "__main__":
    pdf_path = "/com.docker.devenvironments.code/data/pdf_data/LayoutLM.pdf"
    content = parsing_content(pdf_path)
    print(content)
