import UIKit

final class KeyboardViewController: UIInputViewController {
    private let stack = UIStackView()
    private let actions = ["润色", "委婉", "高情商", "简短", "更多"]
    private let letterRows = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["⇧", "z", "x", "c", "v", "b", "n", "m", "⌫"],
        ["🌐", "123", "空格", "回车"]
    ]
    private let numberRows = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["-", "/", ":", ";", "(", ")", "¥", "&", "@", "\""],
        ["ABC", "，", "。", "？", "！", "、", "：", "；", "⌫"],
        ["🌐", "123", "空格", "回车"]
    ]
    private let recipients = ["朋友", "同事", "老板", "客户", "对象"]
    private let moreActions = ["催一下", "拒绝", "道歉", "感谢", "安慰", "夸人", "求帮忙", "提意见", "结束聊天"]

    private enum Panel {
        case none
        case pinyin
        case candidates
        case moreActions
        case recipients
    }

    private var selectedRecipient = "同事"
    private var selectedStyle = "高情商"
    private var isShifted = false
    private var isNumberLayout = false
    private var panel: Panel = .none
    private var activeAction = "润色"
    private var candidates: [String] = []
    private var isGenerating = false
    private var statusMessage: String?
    private var pinyinBuffer = ""
    private var associationCandidates: [String] = []

    private let pinyinSyllables: Set<String> = [
        "a", "ai", "an", "ang", "ao",
        "ba", "bai", "ban", "bang", "bao", "bei", "ben", "beng", "bi", "bian", "biao", "bie", "bin", "bing", "bo", "bu",
        "ca", "cai", "can", "cang", "cao", "ce", "cen", "ceng", "cha", "chai", "chan", "chang", "chao", "che", "chen", "cheng", "chi", "chong", "chou", "chu", "chuai", "chuan", "chuang", "chui", "chun", "chuo", "ci", "cong", "cou", "cu", "cuan", "cui", "cun", "cuo",
        "da", "dai", "dan", "dang", "dao", "de", "dei", "den", "deng", "di", "dian", "diao", "die", "ding", "diu", "dong", "dou", "du", "duan", "dui", "dun", "duo",
        "e", "ei", "en", "eng", "er",
        "fa", "fan", "fang", "fei", "fen", "feng", "fo", "fou", "fu",
        "ga", "gai", "gan", "gang", "gao", "ge", "gei", "gen", "geng", "gong", "gou", "gu", "gua", "guai", "guan", "guang", "gui", "gun", "guo",
        "ha", "hai", "han", "hang", "hao", "he", "hei", "hen", "heng", "hong", "hou", "hu", "hua", "huai", "huan", "huang", "hui", "hun", "huo",
        "ji", "jia", "jian", "jiang", "jiao", "jie", "jin", "jing", "jiong", "jiu", "ju", "juan", "jue", "jun",
        "ka", "kai", "kan", "kang", "kao", "ke", "kei", "ken", "keng", "kong", "kou", "ku", "kua", "kuai", "kuan", "kuang", "kui", "kun", "kuo",
        "la", "lai", "lan", "lang", "lao", "le", "lei", "leng", "li", "lia", "lian", "liang", "liao", "lie", "lin", "ling", "liu", "long", "lou", "lu", "luan", "lun", "luo", "lv", "lve",
        "ma", "mai", "man", "mang", "mao", "me", "mei", "men", "meng", "mi", "mian", "miao", "mie", "min", "ming", "miu", "mo", "mou", "mu",
        "na", "nai", "nan", "nang", "nao", "ne", "nei", "nen", "neng", "ni", "nian", "niang", "niao", "nie", "nin", "ning", "niu", "nong", "nou", "nu", "nuan", "nuo", "nv", "nve",
        "o", "ou",
        "pa", "pai", "pan", "pang", "pao", "pei", "pen", "peng", "pi", "pian", "piao", "pie", "pin", "ping", "po", "pou", "pu",
        "qi", "qia", "qian", "qiang", "qiao", "qie", "qin", "qing", "qiong", "qiu", "qu", "quan", "que", "qun",
        "ran", "rang", "rao", "re", "ren", "reng", "ri", "rong", "rou", "ru", "ruan", "rui", "run", "ruo",
        "sa", "sai", "san", "sang", "sao", "se", "sen", "seng", "sha", "shai", "shan", "shang", "shao", "she", "shei", "shen", "sheng", "shi", "shou", "shu", "shua", "shuai", "shuan", "shuang", "shui", "shun", "shuo", "si", "song", "sou", "su", "suan", "sui", "sun", "suo",
        "ta", "tai", "tan", "tang", "tao", "te", "teng", "ti", "tian", "tiao", "tie", "ting", "tong", "tou", "tu", "tuan", "tui", "tun", "tuo",
        "wa", "wai", "wan", "wang", "wei", "wen", "weng", "wo", "wu",
        "xi", "xia", "xian", "xiang", "xiao", "xie", "xin", "xing", "xiong", "xiu", "xu", "xuan", "xue", "xun",
        "ya", "yan", "yang", "yao", "ye", "yi", "yin", "ying", "yo", "yong", "you", "yu", "yuan", "yue", "yun",
        "za", "zai", "zan", "zang", "zao", "ze", "zei", "zen", "zeng", "zha", "zhai", "zhan", "zhang", "zhao", "zhe", "zhei", "zhen", "zheng", "zhi", "zhong", "zhou", "zhu", "zhua", "zhuai", "zhuan", "zhuang", "zhui", "zhun", "zhuo", "zi", "zong", "zou", "zu", "zuan", "zui", "zun", "zuo"
    ]

    private let characterDict: [String: [String]] = [
        "a": ["啊", "阿", "吖"],
        "ai": ["爱", "哎", "唉", "矮", "挨"],
        "an": ["安", "按", "暗", "岸", "案"],
        "ang": ["昂"],
        "ao": ["奥", "傲", "熬"],
        "ba": ["吧", "把", "爸", "八", "拔"],
        "bai": ["白", "百", "摆", "败", "拜"],
        "ban": ["办", "班", "半", "般", "板"],
        "bang": ["帮", "棒", "绑", "傍", "榜"],
        "bao": ["包", "报", "抱", "保", "爆"],
        "bei": ["被", "北", "杯", "备", "背"],
        "ben": ["本", "笨", "奔"],
        "beng": ["蹦", "崩"],
        "bi": ["比", "必", "笔", "毕", "逼"],
        "bian": ["变", "边", "便", "编", "遍"],
        "biao": ["表", "标", "彪", "飚"],
        "bie": ["别", "憋", "鳖"],
        "bin": ["宾", "彬"],
        "bing": ["并", "病", "冰", "兵", "饼"],
        "bo": ["不", "播", "波", "博", "薄"],
        "bu": ["不", "部", "补", "步", "布"],
        "ca": ["擦"],
        "cai": ["才", "菜", "猜", "财", "采"],
        "can": ["参", "餐", "惨", "残", "灿"],
        "cang": ["藏", "仓"],
        "cao": ["草", "操", "槽"],
        "ce": ["测", "侧", "策", "册"],
        "ceng": ["层", "曾"],
        "cha": ["查", "差", "茶", "插", "察"],
        "chai": ["拆", "柴"],
        "chan": ["产", "馋", "铲"],
        "chang": ["长", "常", "场", "唱", "尝"],
        "chao": ["超", "吵", "潮", "抄"],
        "che": ["车", "撤", "扯"],
        "chen": ["称", "陈", "趁"],
        "cheng": ["成", "城", "诚", "程", "称"],
        "chi": ["吃", "迟", "持", "尺", "齿"],
        "chong": ["重", "充", "冲", "虫"],
        "chou": ["丑", "抽", "愁", "臭"],
        "chu": ["出", "处", "楚", "初", "除"],
        "chuai": ["揣"],
        "chuan": ["穿", "传", "船", "串"],
        "chuang": ["窗", "床", "创", "闯"],
        "chui": ["吹", "垂", "锤"],
        "chun": ["春", "纯", "蠢"],
        "ci": ["次", "此", "词", "刺"],
        "cong": ["从", "聪", "匆", "丛"],
        "cou": ["凑"],
        "cu": ["粗", "醋", "促"],
        "cui": ["催", "脆", "翠"],
        "cun": ["存", "村", "寸"],
        "cuo": ["错", "搓", "措"],
        "da": ["打", "大", "答", "达"],
        "dai": ["带", "待", "代", "戴", "袋"],
        "dan": ["但", "单", "担", "蛋", "淡"],
        "dang": ["当", "档", "挡", "党"],
        "dao": ["到", "道", "倒", "导", "岛"],
        "de": ["的", "得", "地", "德"],
        "dei": ["得"],
        "deng": ["等", "灯", "登", "邓"],
        "di": ["第", "低", "递", "地", "底"],
        "dian": ["点", "店", "电", "典", "掂"],
        "diao": ["掉", "调", "吊", "钓"],
        "die": ["跌", "爹", "叠"],
        "ding": ["定", "顶", "订", "盯"],
        "diu": ["丢"],
        "dong": ["懂", "动", "东", "冬", "冻"],
        "dou": ["都", "豆", "抖", "逗"],
        "du": ["读", "度", "都", "独", "堵"],
        "duan": ["段", "短", "断", "端"],
        "dui": ["对", "队", "堆"],
        "dun": ["顿", "吨", "蹲"],
        "duo": ["多", "躲", "夺", "朵"],
        "e": ["恶", "饿", "额", "俄"],
        "en": ["嗯", "恩"],
        "er": ["二", "尔", "而", "儿"],
        "fa": ["发", "法", "罚", "乏"],
        "fan": ["烦", "饭", "反", "翻", "范"],
        "fang": ["方", "放", "房", "防", "访"],
        "fei": ["非", "费", "飞", "肥"],
        "fen": ["分", "份", "粉", "纷", "奋"],
        "feng": ["风", "封", "疯", "丰", "缝"],
        "fo": ["佛"],
        "fou": ["否"],
        "fu": ["服", "付", "复", "父", "福"],
        "ga": ["嘎"],
        "gai": ["该", "改", "盖", "概"],
        "gan": ["赶", "感", "干", "敢", "竿"],
        "gang": ["刚", "岗", "钢", "港"],
        "gao": ["搞", "高", "告", "糕"],
        "ge": ["个", "各", "哥", "歌", "格"],
        "gei": ["给"],
        "gen": ["跟", "根"],
        "geng": ["更", "耕"],
        "gong": ["工", "公", "功", "共", "供"],
        "gou": ["狗", "够", "构", "购"],
        "gu": ["故", "顾", "古", "股", "鼓"],
        "gua": ["挂", "刮", "瓜"],
        "guai": ["怪", "拐", "乖"],
        "guan": ["关", "管", "观", "官", "馆"],
        "guang": ["光", "广", "逛"],
        "gui": ["鬼", "贵", "归", "规", "桂"],
        "gun": ["滚", "棍"],
        "guo": ["过", "国", "果", "郭"],
        "ha": ["哈"],
        "hai": ["还", "海", "害", "孩"],
        "han": ["喊", "汉", "寒", "含", "韩"],
        "hang": ["行", "航"],
        "hao": ["好", "号", "浩", "豪", "毫"],
        "he": ["和", "喝", "合", "河", "何"],
        "hei": ["黑", "嘿"],
        "hen": ["很", "狠", "恨"],
        "heng": ["哼", "横", "恒"],
        "hong": ["红", "哄", "洪", "宏"],
        "hou": ["后", "候", "厚", "猴"],
        "hu": ["互", "虎", "户", "湖", "胡"],
        "hua": ["话", "花", "画", "化", "华"],
        "huai": ["坏", "怀", "淮"],
        "huan": ["还", "换", "环", "欢", "缓"],
        "huang": ["黄", "慌", "晃", "皇"],
        "hui": ["会", "回", "灰", "挥", "汇"],
        "hun": ["混", "昏", "婚"],
        "huo": ["活", "火", "或", "伙", "货"],
        "ji": ["急", "几", "记", "机", "级"],
        "jia": ["加", "家", "假", "价", "架"],
        "jian": ["见", "件", "间", "简", "建"],
        "jiang": ["讲", "将", "奖", "降", "江"],
        "jiao": ["叫", "交", "教", "角", "脚"],
        "jie": ["接", "姐", "借", "解", "界"],
        "jin": ["进", "今", "紧", "金", "近"],
        "jing": ["经", "竟", "静", "精", "景"],
        "jiong": ["窘", "炯"],
        "jiu": ["就", "久", "九", "旧", "救"],
        "ju": ["句", "据", "举", "具", "局"],
        "juan": ["卷", "捐", "圈"],
        "jue": ["觉", "决", "绝", "掘"],
        "jun": ["军", "均", "俊", "君"],
        "ka": ["卡"],
        "kai": ["开", "凯", "楷"],
        "kan": ["看", "砍", "侃"],
        "kang": ["抗", "康", "扛"],
        "kao": ["靠", "考", "烤"],
        "ke": ["可", "客", "课", "科", "刻"],
        "ken": ["肯", "啃", "恳"],
        "kong": ["空", "控", "孔"],
        "kou": ["口", "扣", "抠"],
        "ku": ["苦", "哭", "库", "裤"],
        "kua": ["夸", "垮", "跨"],
        "kuai": ["快", "块", "筷"],
        "kuan": ["宽", "款"],
        "kuang": ["况", "框", "狂", "矿"],
        "kui": ["亏", "愧", "葵"],
        "kun": ["困", "捆", "坤"],
        "kuo": ["扩", "阔"],
        "la": ["啦", "拉", "辣", "垃"],
        "lai": ["来", "赖", "莱"],
        "lan": ["蓝", "懒", "栏", "烂"],
        "lang": ["浪", "狼", "朗"],
        "lao": ["老", "劳", "捞", "牢"],
        "le": ["了", "乐", "勒"],
        "lei": ["累", "类", "雷", "泪"],
        "leng": ["冷", "愣"],
        "li": ["里", "理", "离", "力", "利"],
        "lia": ["俩"],
        "lian": ["联", "连", "脸", "练", "恋"],
        "liang": ["两", "亮", "量", "凉", "辆"],
        "liao": ["了", "聊", "料", "辽"],
        "lie": ["列", "裂", "烈", "猎"],
        "lin": ["林", "临", "邻", "淋"],
        "ling": ["另", "领", "零", "灵", "令"],
        "liu": ["六", "留", "流", "刘", "溜"],
        "long": ["龙", "拢", "笼", "隆"],
        "lou": ["楼", "漏", "露"],
        "lu": ["路", "录", "陆", "露", "鲁"],
        "luan": ["乱", "卵"],
        "lun": ["论", "轮", "伦"],
        "luo": ["落", "罗", "裸", "络"],
        "lv": ["绿", "率", "旅", "律"],
        "lve": ["略", "掠"],
        "ma": ["吗", "嘛", "妈", "马", "码"],
        "mai": ["买", "卖", "埋", "迈"],
        "man": ["慢", "满", "蛮", "漫"],
        "mang": ["忙", "盲", "茫"],
        "mao": ["毛", "猫", "冒", "贸", "帽"],
        "me": ["么"],
        "mei": ["没", "每", "美", "妹", "梅"],
        "men": ["们", "门", "闷"],
        "meng": ["梦", "猛", "蒙", "盟"],
        "mi": ["迷", "密", "米", "秘"],
        "mian": ["面", "免", "棉", "眠"],
        "miao": ["秒", "妙", "描", "庙"],
        "mie": ["灭", "蔑"],
        "min": ["民", "敏"],
        "ming": ["明", "名", "命", "鸣"],
        "mo": ["摸", "磨", "末", "魔", "莫"],
        "mou": ["某", "谋"],
        "mu": ["目", "母", "木", "幕", "慕"],
        "na": ["那", "哪", "拿", "纳"],
        "nai": ["奶", "奈", "耐"],
        "nan": ["难", "男", "南"],
        "nao": ["闹", "脑", "恼"],
        "ne": ["呢"],
        "nei": ["内"],
        "nen": ["嫩"],
        "neng": ["能"],
        "ni": ["你", "呢", "尼", "泥", "拟"],
        "nian": ["年", "念", "黏", "碾"],
        "niang": ["娘", "酿"],
        "niao": ["鸟", "尿"],
        "nie": ["捏", "聂"],
        "nin": ["您"],
        "ning": ["宁", "拧", "凝"],
        "niu": ["牛", "扭", "纽"],
        "nong": ["弄", "农", "浓"],
        "nu": ["努", "怒"],
        "nuan": ["暖"],
        "nuo": ["诺", "挪"],
        "nv": ["女"],
        "nve": ["虐"],
        "o": ["哦"],
        "ou": ["偶", "欧", "呕"],
        "pa": ["怕", "爬", "趴"],
        "pai": ["拍", "排", "牌", "派"],
        "pan": ["判", "盘", "盼", "攀"],
        "pang": ["旁", "胖"],
        "pao": ["跑", "泡", "炮"],
        "pei": ["配", "陪", "赔", "佩"],
        "pen": ["喷", "盆"],
        "peng": ["朋", "碰", "捧", "棚"],
        "pi": ["批", "皮", "屁", "匹"],
        "pian": ["片", "骗", "偏", "篇"],
        "piao": ["票", "飘", "漂"],
        "pie": ["撇"],
        "pin": ["品", "拼", "频"],
        "ping": ["平", "评", "凭", "瓶", "苹"],
        "po": ["破", "泼", "颇", "迫"],
        "pu": ["普", "铺", "扑", "朴"],
        "qi": ["起", "气", "七", "期", "奇"],
        "qia": ["恰", "掐"],
        "qian": ["前", "钱", "千", "签", "欠"],
        "qiang": ["强", "抢", "墙", "呛"],
        "qiao": ["桥", "巧", "敲", "瞧"],
        "qie": ["且", "切", "窃"],
        "qin": ["亲", "勤", "琴", "秦"],
        "qing": ["请", "清", "轻", "情", "青"],
        "qiong": ["穷", "琼"],
        "qiu": ["球", "求", "秋", "丘"],
        "qu": ["去", "取", "区", "趣", "曲"],
        "quan": ["全", "权", "圈", "劝", "泉"],
        "que": ["却", "确", "缺", "雀"],
        "qun": ["群", "裙"],
        "ran": ["然", "染", "燃"],
        "rang": ["让", "嚷", "壤"],
        "rao": ["绕", "扰"],
        "re": ["热", "惹"],
        "ren": ["人", "认", "任", "忍"],
        "reng": ["仍", "扔"],
        "ri": ["日"],
        "rong": ["容", "荣", "融", "绒"],
        "rou": ["肉", "柔", "揉"],
        "ru": ["如", "入", "乳"],
        "ruan": ["软"],
        "rui": ["瑞", "锐", "睿"],
        "run": ["润", "闰"],
        "ruo": ["若", "弱"],
        "sa": ["洒", "撒"],
        "sai": ["赛", "塞", "腮"],
        "san": ["三", "散", "伞"],
        "sang": ["嗓", "丧", "桑"],
        "sao": ["扫", "骚", "嫂"],
        "se": ["色", "涩"],
        "sen": ["森"],
        "sha": ["啥", "杀", "傻", "沙"],
        "shai": ["晒", "筛"],
        "shan": ["山", "善", "闪", "删"],
        "shang": ["上", "伤", "商", "赏"],
        "shao": ["少", "烧", "绍", "稍"],
        "she": ["社", "设", "蛇", "射"],
        "shei": ["谁"],
        "shen": ["什", "深", "身", "神", "审"],
        "sheng": ["生", "声", "省", "胜", "升"],
        "shi": ["是", "事", "时", "十", "使"],
        "shou": ["手", "受", "收", "首", "售"],
        "shu": ["书", "数", "输", "树", "属"],
        "shua": ["刷", "耍"],
        "shuai": ["帅", "摔", "甩"],
        "shuan": ["拴"],
        "shuang": ["双", "爽", "霜"],
        "shui": ["水", "谁", "睡", "税"],
        "shun": ["顺", "瞬", "舜"],
        "shuo": ["说", "硕"],
        "si": ["四", "死", "思", "丝", "私"],
        "song": ["送", "松", "宋"],
        "sou": ["搜", "艘", "嗽"],
        "su": ["速", "苏", "素", "诉"],
        "suan": ["算", "酸", "蒜"],
        "sui": ["岁", "虽", "随", "碎"],
        "sun": ["孙", "损", "笋"],
        "suo": ["所", "锁", "缩", "索"],
        "ta": ["他", "她", "它", "踏"],
        "tai": ["太", "台", "抬", "态"],
        "tan": ["谈", "弹", "叹", "贪", "摊"],
        "tang": ["躺", "糖", "汤", "堂"],
        "tao": ["套", "逃", "讨", "桃"],
        "te": ["特"],
        "teng": ["疼", "腾"],
        "ti": ["提", "替", "题", "踢"],
        "tian": ["天", "填", "甜", "田"],
        "tiao": ["条", "跳", "挑", "调"],
        "tie": ["铁", "贴"],
        "ting": ["挺", "听", "停", "庭"],
        "tong": ["同", "通", "痛", "统"],
        "tou": ["头", "投", "偷", "透"],
        "tu": ["图", "土", "兔", "突"],
        "tuan": ["团"],
        "tui": ["推", "退", "腿"],
        "tun": ["吞", "屯"],
        "tuo": ["脱", "拖", "托", "妥"],
        "wa": ["哇", "瓦", "挖", "蛙"],
        "wai": ["外", "歪"],
        "wan": ["完", "万", "晚", "玩", "碗"],
        "wang": ["往", "网", "望", "忘", "王"],
        "wei": ["为", "位", "未", "微", "围"],
        "wen": ["问", "文", "闻", "稳", "温"],
        "weng": ["翁"],
        "wo": ["我", "握", "窝"],
        "wu": ["无", "五", "物", "务", "午"],
        "xi": ["西", "希", "洗", "细", "喜"],
        "xia": ["下", "吓", "夏", "虾", "峡"],
        "xian": ["先", "现", "线", "显", "限"],
        "xiang": ["想", "像", "向", "香", "相"],
        "xiao": ["小", "笑", "消", "效", "校"],
        "xie": ["谢", "写", "些", "鞋", "协"],
        "xin": ["新", "心", "信", "辛"],
        "xing": ["行", "性", "星", "兴", "型"],
        "xiong": ["兄", "胸", "熊", "凶"],
        "xiu": ["修", "休", "秀", "袖"],
        "xu": ["需", "许", "续", "须", "徐"],
        "xuan": ["选", "宣", "旋", "悬"],
        "xue": ["学", "血", "雪", "穴"],
        "xun": ["寻", "训", "迅", "询"],
        "ya": ["呀", "压", "牙", "鸭"],
        "yan": ["眼", "言", "演", "严", "烟"],
        "yang": ["样", "养", "羊", "洋", "阳"],
        "yao": ["要", "邀", "药", "摇", "咬"],
        "ye": ["也", "页", "业", "夜", "叶"],
        "yi": ["一", "已", "以", "意", "易"],
        "yin": ["因", "音", "引", "印", "银"],
        "ying": ["应", "影", "英", "迎", "硬"],
        "yo": ["哟"],
        "yong": ["用", "永", "勇", "拥"],
        "you": ["有", "又", "友", "由", "优"],
        "yu": ["与", "于", "语", "雨", "预"],
        "yuan": ["远", "原", "愿", "元", "园"],
        "yue": ["月", "越", "约", "阅"],
        "yun": ["运", "云", "允", "孕"],
        "za": ["砸", "杂"],
        "zai": ["在", "再", "载"],
        "zan": ["赞", "咱", "攒"],
        "zang": ["脏", "藏"],
        "zao": ["早", "造", "遭", "糟"],
        "ze": ["则", "责", "择"],
        "zei": ["贼"],
        "zen": ["怎"],
        "zeng": ["增", "赠", "曾"],
        "zha": ["炸", "扎", "渣", "眨"],
        "zhai": ["摘", "宅", "窄", "债"],
        "zhan": ["站", "占", "战", "展", "粘"],
        "zhang": ["张", "长", "掌", "章", "丈"],
        "zhao": ["找", "照", "招", "赵", "罩"],
        "zhe": ["这", "着", "折", "者"],
        "zhen": ["真", "阵", "针", "震", "振"],
        "zheng": ["正", "整", "证", "争", "政"],
        "zhi": ["知", "只", "之", "直", "指"],
        "zhong": ["中", "重", "种", "终", "众"],
        "zhou": ["周", "走", "州", "粥"],
        "zhu": ["主", "住", "注", "助", "猪"],
        "zhua": ["抓", "爪"],
        "zhuai": ["拽"],
        "zhuan": ["转", "专", "赚", "砖"],
        "zhuang": ["装", "撞", "壮", "状"],
        "zhui": ["追", "坠"],
        "zhun": ["准"],
        "zhuo": ["捉", "桌", "着"],
        "zi": ["自", "字", "子", "资"],
        "zong": ["总", "纵", "宗", "综"],
        "zou": ["走", "奏", "揍"],
        "zu": ["组", "足", "族", "租"],
        "zuan": ["钻"],
        "zui": ["最", "醉", "罪", "嘴"],
        "zun": ["遵", "尊"],
        "zuo": ["做", "作", "坐", "左", "昨"]
    ]

    private let associationDictionary: [String: [String]] = [
        "我": ["想", "觉得", "这边", "先", "可以"],
        "我想": ["确认一下", "问一下", "说的是", "知道", "看看"],
        "你": ["看", "这边", "方便", "可以", "先"],
        "你好": ["在吗", "最近怎么样", "好久不见", "打扰一下", "有个事问你"],
        "您": ["看", "这边", "方便", "先", "可以"],
        "好": ["的", "呀", "啊", "我知道了", "没问题"],
        "好的": ["我知道了", "那就这样", "辛苦啦", "我马上看", "谢谢"],
        "可以": ["的", "呀", "我来处理", "没问题", "稍等一下"],
        "不": ["好意思", "太方便", "用了", "确定", "着急"],
        "不好": ["意思", "说", "处理", "麻烦你了", "弄"],
        "不好意思": ["麻烦你了", "我这边刚看到", "这次是我的问题", "让你久等了", "我马上处理"],
        "没": ["事", "关系", "问题", "看到", "来得及"],
        "没事": ["的", "不用急", "我理解", "下次再说", "你先忙"],
        "谢谢": ["你", "啦", "辛苦啦", "我收到了", "太感谢了"],
        "对不起": ["让你久等了", "这次是我的问题", "我马上处理", "给你添麻烦了", "我会注意"],
        "怎么": ["了", "还", "说", "处理", "安排"],
        "怎么还": ["没发给我", "没到", "没处理", "没回复", "没开始"],
        "发给我": ["一下", "可以吗", "看看", "就行", "谢谢"],
        "在吗": ["有个事想问你", "方便说一下吗", "我想确认个事", "看到回我一下", "打扰一下"],
        "今天": ["方便吗", "可以吗", "有空吗", "能发我吗", "辛苦你了"],
        "这个": ["资料", "事情", "问题", "方案", "时间"],
        "资料": ["方便发我一下吗", "我这边要用", "辛苦你了", "今天能发吗", "我看一下"],
        "辛苦": ["啦", "你了", "麻烦你了", "帮我看下", "这边确认下"],
        "麻烦": ["你了", "帮我看下", "发我一下", "确认一下", "辛苦啦"],
        "老板": ["您看", "这边", "方便", "我确认下", "辛苦您"],
        "客户": ["您好", "这边", "方便的话", "辛苦您", "我确认一下"],
        "朋友": ["哈哈", "你看", "有空吗", "一起", "下次约"],
        "明天": ["见", "有空吗", "可以吗", "再说", "几点"],
        "现在": ["方便吗", "在忙吗", "有时间吗", "可以吗", "在哪里"],
        "知道": ["了", "的", "啦", "就好", "就行"]
    ]

    private var isDark: Bool {
        traitCollection.userInterfaceStyle == .dark
    }

    private var kbBg: UIColor {
        isDark ? UIColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1) : UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1)
    }

    private var keyBg: UIColor {
        isDark ? UIColor(red: 0.28, green: 0.28, blue: 0.30, alpha: 1) : .white
    }

    private var keyFg: UIColor {
        isDark ? UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1) : UIColor(red: 0.07, green: 0.09, blue: 0.15, alpha: 1)
    }

    private var panelBg: UIColor {
        isDark ? UIColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1) : UIColor(red: 0.976, green: 0.980, blue: 0.984, alpha: 1)
    }

    private var subFg: UIColor {
        isDark ? UIColor(red: 0.65, green: 0.67, blue: 0.70, alpha: 1) : UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 1)
    }

    private var specBg: UIColor {
        isDark ? UIColor(red: 0.50, green: 0.55, blue: 0.60, alpha: 1) : UIColor(red: 0.820, green: 0.835, blue: 0.859, alpha: 1)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedRecipient = SharedSettings.defaultRecipient
        selectedStyle = SharedSettings.style(for: selectedRecipient)
        view.backgroundColor = kbBg
        configureStack()
        renderKeyboard()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            view.backgroundColor = kbBg
            renderKeyboard()
        }
    }

    private func configureStack() {
        stack.axis = .vertical
        stack.spacing = 7
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
    }

    private func renderKeyboard() {
        stack.arrangedSubviews.forEach { subview in
            stack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }

        let recipient = button(title: "发给：\(selectedRecipient)  \(selectedStyle) ▾", isAction: true)
        stack.addArrangedSubview(recipient)

        let actionRow = UIStackView()
        actionRow.axis = .horizontal
        actionRow.spacing = 6
        actionRow.distribution = .fillEqually
        for action in actions {
            actionRow.addArrangedSubview(button(title: action, isAction: true, highlighted: action == activeAction && panel == .candidates))
        }
        stack.addArrangedSubview(actionRow)

        switch panel {
        case .candidates:
            stack.addArrangedSubview(candidatePanel())
        case .moreActions:
            stack.addArrangedSubview(moreActionsPanel())
        case .recipients:
            stack.addArrangedSubview(recipientsPanel())
        case .pinyin, .none:
            break
        }

        if !pinyinBuffer.isEmpty {
            stack.addArrangedSubview(inlinePinyinBar())
        }

        let currentRows = isNumberLayout ? numberRows : letterRows
        for row in currentRows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 5
            rowStack.distribution = .fillEqually

            for key in row {
                let title = displayTitle(for: key)
                rowStack.addArrangedSubview(button(title: title, isAction: false, highlighted: key == "⇧" && isShifted))
            }

            stack.addArrangedSubview(rowStack)
        }
    }

    private func displayTitle(for key: String) -> String {
        guard key.count == 1, key >= "a", key <= "z" else { return key }
        return isShifted ? key.uppercased() : key
    }

    private func button(title: String, isAction: Bool, highlighted: Bool = false) -> UIButton {
        let isSpecial = ["⇧", "⌫", "🌐", "123", "ABC", "空格", "回车"].contains(title)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseForegroundColor = highlighted ? .white : keyFg
        config.baseBackgroundColor = highlighted ? UIColor(red: 0.086, green: 0.639, blue: 0.290, alpha: 1) : (isSpecial ? specBg : keyBg)
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 4, bottom: 5, trailing: 4)

        if title == "润色" && panel != .candidates {
            config.baseForegroundColor = .white
            config.baseBackgroundColor = UIColor(red: 0.086, green: 0.639, blue: 0.290, alpha: 1)
        }

        let button = UIButton(configuration: config)
        button.titleLabel?.font = .systemFont(ofSize: isAction ? 13 : 18, weight: isAction ? .bold : .medium)
        button.heightAnchor.constraint(equalToConstant: isAction ? 34 : 41).isActive = true
        button.addAction(UIAction { [weak self] _ in
            self?.handleTap(title)
        }, for: .touchUpInside)
        return button
    }

    private func candidatePanel() -> UIView {
        let panelStack = UIStackView()
        panelStack.axis = .vertical
        panelStack.spacing = 6
        panelStack.backgroundColor = panelBg
        panelStack.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        panelStack.isLayoutMarginsRelativeArrangement = true

        let title = UILabel()
        if isGenerating {
            title.text = "\(selectedRecipient) · \(activeAction) · 正在生成..."
        } else if let statusMessage {
            title.text = statusMessage
        } else {
            title.text = candidates.isEmpty ? "先输入一句原话，再点击动作" : "\(selectedRecipient) · \(activeAction) · 选择一条替换输入"
        }
        title.font = .systemFont(ofSize: 12, weight: .semibold)
        title.textColor = subFg
        panelStack.addArrangedSubview(title)

        for candidate in candidates {
            var config = UIButton.Configuration.filled()
            config.title = candidate
            config.baseForegroundColor = keyFg
            config.baseBackgroundColor = keyBg
            config.cornerStyle = .medium
            config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 8)

            let candidateButton = UIButton(configuration: config)
            candidateButton.titleLabel?.font = .systemFont(ofSize: 14)
            candidateButton.titleLabel?.numberOfLines = 2
            candidateButton.contentHorizontalAlignment = .leading
            candidateButton.addAction(UIAction { [weak self] _ in
                self?.replaceCurrentInput(with: candidate)
            }, for: .touchUpInside)
            panelStack.addArrangedSubview(candidateButton)
        }

        return panelStack
    }

    private func pinyinPanel() -> UIView {
        let panelStack = UIStackView()
        panelStack.axis = .vertical
        panelStack.spacing = 6
        panelStack.backgroundColor = panelBg
        panelStack.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        panelStack.isLayoutMarginsRelativeArrangement = true

        let title = UILabel()
        title.text = pinyinBuffer.isEmpty ? "联想" : "拼音：\(pinyinBuffer)"
        title.font = .systemFont(ofSize: 12, weight: .semibold)
        title.textColor = subFg
        panelStack.addArrangedSubview(title)

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.distribution = .fillEqually

        for candidate in inputSuggestions() {
            var config = UIButton.Configuration.filled()
            config.title = candidate
            config.baseForegroundColor = keyFg
            config.baseBackgroundColor = keyBg
            config.cornerStyle = .medium
            config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 8)

            let candidateButton = UIButton(configuration: config)
            candidateButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            candidateButton.addAction(UIAction { [weak self] _ in
                self?.commitPinyin(candidate)
            }, for: .touchUpInside)
            row.addArrangedSubview(candidateButton)
        }

        panelStack.addArrangedSubview(row)
        return panelStack
    }

    private func moreActionsPanel() -> UIView {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 6
        grid.backgroundColor = panelBg
        grid.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        grid.isLayoutMarginsRelativeArrangement = true

        for chunkStart in stride(from: 0, to: moreActions.count, by: 3) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 6
            row.distribution = .fillEqually

            for action in moreActions[chunkStart..<min(chunkStart + 3, moreActions.count)] {
                row.addArrangedSubview(button(title: action, isAction: true))
            }

            grid.addArrangedSubview(row)
        }

        return grid
    }

    private func recipientsPanel() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 6
        container.backgroundColor = panelBg
        container.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        container.isLayoutMarginsRelativeArrangement = true

        let recipientRow = UIStackView()
        recipientRow.axis = .horizontal
        recipientRow.spacing = 6
        recipientRow.distribution = .fillEqually
        for recipient in recipients {
            recipientRow.addArrangedSubview(button(title: recipient, isAction: true, highlighted: recipient == selectedRecipient))
        }
        container.addArrangedSubview(recipientRow)

        let styleRow = UIStackView()
        styleRow.axis = .horizontal
        styleRow.spacing = 6
        styleRow.distribution = .fillEqually
        for style in SharedSettings.allStyles {
            styleRow.addArrangedSubview(button(title: style, isAction: true, highlighted: style == selectedStyle))
        }
        container.addArrangedSubview(styleRow)

        return container
    }

    private func handleTap(_ title: String) {
        switch title {
        case "⌫":
            if pinyinBuffer.isEmpty {
                associationCandidates = []
                textDocumentProxy.deleteBackward()
            } else {
                pinyinBuffer.removeLast()
                renderKeyboard()
            }
        case "空格":
            if pinyinBuffer.isEmpty {
                textDocumentProxy.insertText(" ")
                associationCandidates = []
                renderKeyboard()
            } else {
                commitPinyin(inputSuggestions().first ?? pinyinBuffer)
            }
        case "回车":
            if pinyinBuffer.isEmpty {
                textDocumentProxy.insertText("\n")
                associationCandidates = []
                renderKeyboard()
            } else {
                commitPinyin(inputSuggestions().first ?? pinyinBuffer)
            }
        case "🌐":
            advanceToNextInputMode()
        case "润色", "委婉", "高情商", "简短", "更多":
            commitPendingPinyinIfNeeded()
            handleAction(title)
        case "催一下", "拒绝", "道歉", "感谢", "安慰", "夸人", "求帮忙", "提意见", "结束聊天":
            showCandidates(for: title)
        case "发给：\(selectedRecipient)  \(selectedStyle) ▾":
            panel = .recipients
            renderKeyboard()
        case "朋友", "同事", "老板", "客户", "对象":
            selectedRecipient = title
            selectedStyle = SharedSettings.style(for: title)
            SharedSettings.defaultRecipient = title
            SharedSettings.synchronize()
            panel = .none
            renderKeyboard()
        case "高情商", "自然温和", "幽默风趣", "油腻大叔", "精神小妹", "专业正式", "礼貌克制":
            selectedStyle = title
            SharedSettings.setStyle(title, for: selectedRecipient)
            SharedSettings.synchronize()
            panel = .none
            renderKeyboard()
        case "⇧":
            isShifted.toggle()
            renderKeyboard()
        case "123":
            commitPendingPinyinIfNeeded()
            isNumberLayout = true
            isShifted = false
            renderKeyboard()
        case "ABC":
            isNumberLayout = false
            renderKeyboard()
        default:
            insertKey(title)
        }
    }

    private func handleAction(_ title: String) {
        if title == "更多" {
            panel = .moreActions
            renderKeyboard()
        } else {
            showCandidates(for: title)
        }
    }

    private func showCandidates(for action: String) {
        activeAction = action
        let text = currentInputText()
        guard !text.isEmpty else {
            candidates = []
            statusMessage = "先输入一句原话，再点击动作"
            panel = .candidates
            renderKeyboard()
            return
        }

        statusMessage = nil
        panel = .candidates
        candidates = LocalCandidateGenerator.generate(text: text, recipient: selectedRecipient, action: action)

        guard SharedSettings.isAPIConfigured else {
            statusMessage = "未配置 API，已使用本地候选"
            renderKeyboard()
            return
        }

        isGenerating = true
        statusMessage = nil
        renderKeyboard()

        var settings = LLMClient.Settings.current
        settings = LLMClient.Settings(
            endpoint: settings.endpoint,
            model: settings.model,
            apiKey: settings.apiKey,
            recipient: selectedRecipient,
            style: selectedStyle,
            rewriteLevel: settings.rewriteLevel,
            keepVoice: settings.keepVoice,
            noGreasy: settings.noGreasy,
            noEmoji: settings.noEmoji,
            notFormal: settings.notFormal
        )

        Task { [weak self] in
            do {
                let remoteCandidates = try await LLMClient.generateCandidates(text: text, action: action, settings: settings)
                await MainActor.run {
                    guard let self else { return }
                    self.candidates = remoteCandidates
                    self.isGenerating = false
                    self.statusMessage = "AI 已生成，选择一条替换输入"
                    self.renderKeyboard()
                }
            } catch {
                await MainActor.run {
                    guard let self else { return }
                    self.isGenerating = false
                    self.statusMessage = "AI 请求失败，已使用本地候选"
                    self.renderKeyboard()
                }
            }
        }
    }

    private func insertKey(_ title: String) {
        if !isNumberLayout, title.count == 1, title.lowercased() >= "a", title.lowercased() <= "z" {
            associationCandidates = []
            pinyinBuffer += title.lowercased()
            renderKeyboard()
            return
        }

        commitPendingPinyinIfNeeded()
        textDocumentProxy.insertText(title)
        if isShifted, title.count == 1, title >= "A", title <= "Z" {
            isShifted = false
            renderKeyboard()
        }
    }

    private func segmentPinyin(_ input: String) -> [String] {
        guard !input.isEmpty else { return [] }
        var result: [String] = []
        var pos = input.startIndex
        while pos < input.endIndex {
            var found = false
            var len = min(6, input.distance(from: pos, to: input.endIndex))
            while len > 0 {
                let end = input.index(pos, offsetBy: len)
                let sub = String(input[pos..<end])
                if pinyinSyllables.contains(sub) {
                    result.append(sub)
                    pos = end
                    found = true
                    break
                }
                len -= 1
            }
            if !found {
                result.append(String(input[pos]))
                pos = input.index(after: pos)
            }
        }
        return result
    }

    private func segmentedDisplay(_ input: String) -> String {
        segmentPinyin(input).joined(separator: " ")
    }

    private func inputSuggestions() -> [String] {
        if pinyinBuffer.isEmpty {
            let s = associationCandidates
            return Array(s.prefix(8))
        }

        let syllables = segmentPinyin(pinyinBuffer)
        var results: [String] = []

        if syllables.count == 1 {
            if let chars = characterDict[pinyinBuffer] {
                results.append(contentsOf: chars.prefix(5))
            }
            let prefixMatches = characterDict
                .filter { $0.key.hasPrefix(pinyinBuffer) && $0.key != pinyinBuffer }
                .sorted { $0.key.count < $1.key.count }
                .flatMap { $0.value }
            results.append(contentsOf: Array(prefixMatches.prefix(5)))
        } else if syllables.count >= 2 {
            let firstChars = syllables.compactMap { characterDict[$0]?.first }
            if firstChars.count == syllables.count {
                let phrase = firstChars.joined()
                results.append(phrase)
            }
            for i in 0..<min(3, syllables.count) {
                if let chars = characterDict[syllables[i]] {
                    results.append(contentsOf: chars.prefix(2))
                }
            }
        }

        return Array(results.prefix(8))
    }

    private func inlinePinyinBar() -> UIView {
        let bar = UIStackView()
        bar.axis = .horizontal
        bar.spacing = 6
        bar.alignment = .center
        bar.backgroundColor = panelBg
        bar.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        bar.isLayoutMarginsRelativeArrangement = true
        bar.layer.cornerRadius = 8
        bar.layer.masksToBounds = true

        let label = UILabel()
        let seg = segmentedDisplay(pinyinBuffer)
        label.text = associationCandidates.isEmpty ? seg : (seg.isEmpty ? "联想" : seg + "  |  联想")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor(red: 0.086, green: 0.639, blue: 0.290, alpha: 1)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.numberOfLines = 1
        bar.addArrangedSubview(label)

        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false

        let chipStack = UIStackView()
        chipStack.axis = .horizontal
        chipStack.spacing = 5

        for candidate in inputSuggestions() {
            var config = UIButton.Configuration.filled()
            config.title = candidate
            config.baseForegroundColor = keyFg
            config.baseBackgroundColor = keyBg
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)

            let chip = UIButton(configuration: config)
            chip.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            chip.addAction(UIAction { [weak self] _ in
                self?.commitPinyin(candidate)
            }, for: .touchUpInside)
            chipStack.addArrangedSubview(chip)
        }

        scroll.addSubview(chipStack)
        chipStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chipStack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            chipStack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            chipStack.topAnchor.constraint(equalTo: scroll.topAnchor),
            chipStack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            chipStack.heightAnchor.constraint(equalTo: scroll.heightAnchor)
        ])
        bar.addArrangedSubview(scroll)

        return bar
    }

    private func commitPinyin(_ text: String) {
        textDocumentProxy.insertText(text)
        pinyinBuffer = ""
        associationCandidates = associations(for: text)
        renderKeyboard()
    }

    private func commitPendingPinyinIfNeeded() {
        guard !pinyinBuffer.isEmpty else { return }
        let committed = inputSuggestions().first ?? pinyinBuffer
        textDocumentProxy.insertText(committed)
        pinyinBuffer = ""
        associationCandidates = associations(for: committed)
    }

    private func associations(for text: String) -> [String] {
        if let exact = associationDictionary[text] {
            return exact
        }

        let matches = associationDictionary
            .filter { text.hasSuffix($0.key) }
            .sorted { $0.key.count > $1.key.count }
            .flatMap { $0.value }
        return Array(matches.prefix(5))
    }

    private func currentInputText() -> String {
        (textDocumentProxy.documentContextBeforeInput ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func replaceCurrentInput(with text: String) {
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        for _ in context {
            textDocumentProxy.deleteBackward()
        }
        textDocumentProxy.insertText(text)
        pinyinBuffer = ""
        associationCandidates = associations(for: text)
        panel = .none
        renderKeyboard()
    }

}
