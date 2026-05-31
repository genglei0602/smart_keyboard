import Foundation

enum LocalCandidateGenerator {
    static func generate(text: String, recipient: String, action: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let prefix: String
        switch recipient {
        case "老板": prefix = "您看"
        case "客户": prefix = "您这边方便的话"
        case "对象": prefix = "宝，我想说"
        case "朋友": prefix = "我想说哈"
        default: prefix = "我想确认下"
        }

        switch action {
        case "简短":
            return [trimmed, "\(prefix)，\(trimmed)", "关于这个，\(trimmed)"]
        case "委婉":
            return ["\(prefix)，\(trimmed) 可以吗？", "这件事我想和你确认一下：\(trimmed)。", "如果方便的话，\(trimmed)～"]
        case "高情商":
            return ["辛苦啦，\(trimmed) 方便的话麻烦你帮我看下。", "我这边理解你在忙，想跟你确认下：\(trimmed)。", "感谢配合，\(trimmed)，这样我这边也好安排。"]
        case "催一下":
            return ["\(prefix)，\(trimmed)？我这边后面要用到。", "辛苦你了，\(trimmed)，我这边想提前安排。", "想跟你确认下进度：\(trimmed)。"]
        case "拒绝":
            return ["这次我可能不太方便，先不参加了。", "感谢你邀请，我这次先不去了，下次再约。", "我这边时间有点冲突，这次先不参与。"]
        case "道歉":
            return ["不好意思，这件事是我考虑不周。", "抱歉给你添麻烦了，我这边会尽快处理。", "这次确实是我的问题，辛苦你包容一下。"]
        case "感谢":
            return ["谢谢你，真的帮了我很多。", "辛苦啦，感谢你这么快帮我处理。", "太感谢了，这样我这边就好安排了。"]
        case "安慰":
            return ["先别太着急，我们一步一步来。", "我理解你现在不容易，需要的话我在。", "这件事确实挺难受的，你已经做得很好了。"]
        case "夸人":
            return ["你这个处理得很稳，细节也很到位。", "这次真的很厉害，效率和结果都很好。", "我觉得你这个想法挺好，也很有执行力。"]
        case "求帮忙":
            return ["方便的话，想麻烦你帮我看一下这个。", "不知道你这边是否方便帮个忙？", "这件事可能需要你支持一下，辛苦啦。"]
        case "提意见":
            return ["我有个小建议，你看看是否合适。", "这个方向挺好的，我补充一个可能可以优化的点。", "我理解你的思路，也许我们可以再调整一下这里。"]
        case "结束聊天":
            return ["那先这样，后面有进展我再同步你。", "好的，那我先去处理，有需要再联系。", "明白了，今天先到这里，辛苦啦。"]
        default:
            return ["\(prefix)，\(trimmed)。", "我想和你确认一下：\(trimmed)。", "这件事麻烦你看下，\(trimmed)。"]
        }
    }
}
