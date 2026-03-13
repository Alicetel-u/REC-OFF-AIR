const DIALOGUE_CACHE = {
  "ch01_haison_iriguchi": {
    "chapter": "ch01_haison_iriguchi",
    "_note": "CP1 公衆トイレの首無し少女 — 配信開始→解説ウォーク→トイレ→脱出→商店街ゲート",
    "events": [
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【シーン1：スマホ起動・配信開始】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "sfx",
        "sound": "ambient_wind"
      },
      {
        "type": "flashlight_on"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "set_viewers",
        "count": 38
      },
      {
        "type": "say",
        "text": "……あ、映った。みんな、深夜のガチ凸ライブ、霧原村編始まるよー！ 同接10万人いくまで、今日は絶対帰りませーん！",
        "reading": "……あ、映った。みんな、深夜のガチ凸ライブ、霧原村編始まるよー！ どうせつ10万人いくまで、今日は絶対帰りませーん！",
        "voice": "v001"
      },
      {
        "type": "wait",
        "sec": 8.94
      },
      {
        "type": "chat",
        "msg": "きたｗ",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "霧すごすぎ",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "どうせヤラセだろ",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "say",
        "text": "……みんな、今日マジでチャンネル登録とスパチャよろしくね。うち、今月ガチで金欠だからさー。パパ活とか無理だし、これで一発当てるしかないの！",
        "voice": "v002d"
      },
      {
        "type": "wait",
        "sec": 10.37
      },
      {
        "type": "chat",
        "msg": "金欠配信者ｗｗｗ",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "パパ活無理は草",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "スパチャで応援するしかないな",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── 空撮カット：村全体を俯瞰 ──"
      },
      {
        "type": "pos_y",
        "target": 20,
        "dur": 3,
        "id": "aerial"
      },
      {
        "type": "head_x",
        "target": -1,
        "dur": 2.5
      },
      {
        "type": "wait",
        "sec": 3
      },
      {
        "type": "say",
        "text": "霧原村……。ここかぁ。",
        "voice": "v002b"
      },
      {
        "type": "wait",
        "sec": 2.16
      },
      {
        "type": "_comment",
        "_": "── 空撮：見渡しながらv002（rot_yとsayが同時進行） ──"
      },
      {
        "type": "set_viewers",
        "count": 55
      },
      {
        "type": "rot_y",
        "target": -2.5,
        "dur": 7.0
      },
      {
        "type": "say",
        "text": "ヤラセじゃないって！ ほら、見てよこれ。村の入り口の周りに並んでるこの案山子……全部首がないの。",
        "reading": "ヤラセじゃないって！ ほら、見てよこれ。村の入り口の周りに並んでるこの案山子……全部くびがないの。",
        "voice": "v002"
      },
      {
        "type": "wait",
        "sec": 7.34
      },
      {
        "type": "chat",
        "msg": "案山子が多すぎてキモいんだが",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "首なし案山子って時点でやばい",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "head_x",
        "target": 0,
        "dur": 2
      },
      {
        "type": "rot_y",
        "target": -1.57,
        "dur": 1.5
      },
      {
        "type": "pos_y",
        "target": 1,
        "dur": 2.5,
        "id": "aerial_down"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "say",
        "text": "この立ち入り禁止の柵の向こうに行きたいと思いまーす！",
        "voice": "v002c",
        "reading": "この立ち入り禁止の柵の向こうに行きたいと思いまーす！"
      },
      {
        "type": "wait",
        "sec": 3.41
      },
      {
        "type": "chat",
        "msg": "立ち入り禁止って書いてあるだろｗ",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "horror_glitch",
        "intensity": 1,
        "count": 1
      },
      {
        "type": "chat",
        "msg": "見てる",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【シーン2：解説ウォーク — お札説明＆みゆき事件】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "set_viewers",
        "count": 150
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_x",
        "target": 12,
        "dur": 51
      },
      {
        "type": "say",
        "text": "さて……歩きながら説明するね。あたし今、お札を3枚持ってるの。神社をやっている私のおばあちゃんからパク",
        "voice": "v003"
      },
      {
        "type": "wait",
        "sec": 8.38
      },
      {
        "type": "chat",
        "msg": "パクったて",
        "user": "深夜のツッコミ担当"
      },
      {
        "type": "wait",
        "sec": 0.2
      },
      {
        "type": "chat",
        "msg": "今パクッて言った？？？",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "say",
        "text": "いや、もらったんだけどね？ 『これだけは持っていきなさい』って。あたし的にはお守りっていうか、まあ映えアイテムだよね。",
        "voice": "v003b"
      },
      {
        "type": "wait",
        "sec": 7.2
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "窃盗配信で草",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.2
      },
      {
        "type": "chat",
        "msg": "もらったんだけどね（迫真）",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "ばあちゃんの札パクるなｗｗｗ",
        "user": "塩ラーメン"
      },
      {
        "type": "wait",
        "sec": 0.2
      },
      {
        "type": "chat",
        "msg": "映えアイテムは草",
        "user": "暗闇ウォッチャー",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "お札をそういう扱いするの不敬すぎて逆に好き",
        "user": "オカルト研究部"
      },
      {
        "type": "wait",
        "sec": 0.2
      },
      {
        "type": "chat",
        "msg": "フラグにしか聞こえない",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "ばーちゃん泣いてるよ",
        "user": "地蔵キッズ"
      },
      {
        "type": "wait",
        "sec": 0.2
      },
      {
        "type": "chat",
        "msg": "お札3枚＝ライフ3ってこと？",
        "user": "はじめまして民"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "映えアイテムが命綱になるやつだこれ",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "ゲームみたい",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "この村、20年前に『みゆき事件』っていう未解決事件があってさ。17歳の女の子……霧原みゆきちゃんが、村の公衆トイレで首を撥ねられたの。犯人は見つかってない。",
        "voice": "v004",
        "reading": "この村、20年前に『みゆき事件』っていう未解決事件があってさ。17歳の女の子……霧原みゆきちゃんが、村の公衆トイレでくびを撥ねられたの。犯人は見つかってない。"
      },
      {
        "type": "wait",
        "sec": 12.63
      },
      {
        "type": "chat",
        "msg": "ガチの事件じゃん…",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "未解決ってマ？",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "set_viewers",
        "count": 420
      },
      {
        "type": "_comment",
        "_": "── 案山子エリア通過 (x=7.5付近) ──"
      },
      {
        "type": "rot_y",
        "target": -3.14,
        "dur": 1
      },
      {
        "type": "wait",
        "sec": 1
      },
      {
        "type": "say",
        "text": "……ほら、ここ見て。案山子の首の切り口、全部同じ角度なんだよね。まるで刀で一太刀……ぞっとするでしょ。",
        "voice": "v005",
        "reading": "……ほら、ここ見て。案山子のくびの切り口、全部同じ角度なんだよね。まるで刀で一太刀……ぞっとするでしょ。"
      },
      {
        "type": "wait",
        "sec": 8.76
      },
      {
        "type": "rot_y",
        "target": -1.57,
        "dur": 1
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "同じ角度はやばすぎ",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "案山子の首を切る意味…",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "set_viewers",
        "count": 800
      },
      {
        "type": "say",
        "text": "で、それ以来この村の公衆トイレには『みゆきちゃんが出る』って噂があって。首のない女の子が、天井に貼り付いてるらしいの。……カメラ越しにしか見えないんだって。",
        "voice": "v006",
        "reading": "で、それ以来この村の公衆トイレには『みゆきちゃんが出る』って噂があって。くびのない女の子が、天井に貼り付いてるらしいの。……カメラ越しにしか見えないんだって。"
      },
      {
        "type": "wait",
        "sec": 10.64
      },
      {
        "type": "_comment",
        "_": "── 神社の鳥居を見る（x=12到着・立ち止まり） ──"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "rot_y",
        "target": 0,
        "dur": 1.2
      },
      {
        "type": "head_x",
        "target": -0.15,
        "dur": 2.0
      },
      {
        "type": "pos_z",
        "target": -3,
        "dur": 10
      },
      {
        "type": "chat",
        "msg": "カメラ越しにしか見えない系はガチ",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "それ配信向きすぎるだろ",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "行くなよ絶対行くなよ",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 4.44
      },
      {
        "type": "pos_z",
        "target": 3,
        "dur": 2
      },
      {
        "type": "head_x",
        "target": 0,
        "dur": 1.5
      },
      {
        "type": "rot_y",
        "target": -1.57,
        "dur": 1
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "フラグ立てんな",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "大丈夫じゃないやつ",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "_comment",
        "_": "── 歩行再開・区間2開始 ──"
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_x",
        "target": 38,
        "dur": 108,
        "id": "walk_main"
      },
      {
        "type": "set_viewers",
        "count": 2000
      },
      {
        "type": "chat",
        "msg": "同接2000いったぞ",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "superchat",
        "user": "ゴーストハンター",
        "amount": 500,
        "msg": "応援してる！ガチで気をつけて"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── 村門通過 ──"
      },
      {
        "type": "say",
        "text": "村門が見えてきた……。ここから先が霧原村の中心部だね。商店街の奥にあのトイレがあるはず。",
        "voice": "v008"
      },
      {
        "type": "wait",
        "sec": 7.29
      },
      {
        "type": "chat",
        "msg": "もう引き返せないぞ",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "flashlight_flicker"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "ライト不安定じゃない？",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "set_viewers",
        "count": 3500
      },
      {
        "type": "say",
        "text": "よーし、行くよ！ みゆきちゃんに会いに行こう！……って言うとなんか怖いな。",
        "voice": "v009"
      },
      {
        "type": "wait",
        "sec": 4.83
      },
      {
        "type": "chat",
        "msg": "会いに行くなｗｗｗ",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "知りたい？",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "ていうかさ、この村の地面めっちゃぬかるんでるんだけど。スニーカー終わった。新品のナイキなのに。",
        "voice": "v009a"
      },
      {
        "type": "wait",
        "sec": 6.87
      },
      {
        "type": "chat",
        "msg": "優先順位ｗｗｗ",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "命の心配しろ",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "いやだってこれ2万したんだよ！？ バイト代3日分！ ……まあいいや、同接で元取るし。",
        "reading": "いやだってこれ2万したんだよ！？ バイト代3日分！ ……まあいいや、どうせつで元取るし。",
        "voice": "v009b"
      },
      {
        "type": "wait",
        "sec": 6.25
      },
      {
        "type": "chat",
        "msg": "配信で元取るの強すぎ",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "set_viewers",
        "count": 4200
      },
      {
        "type": "superchat",
        "msg": "ナイキ代の足しにして",
        "user": "ガクブル太郎",
        "amount": 200
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "うわスパチャ！ ありがとー！ ……200円じゃ足りないけどね！ あはは！",
        "voice": "v009c"
      },
      {
        "type": "wait",
        "sec": 5.05
      },
      {
        "type": "chat",
        "msg": "ｗｗｗｗ",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "_comment",
        "_": "── 村門くぐった先の異変 ──"
      },
      {
        "type": "sfx",
        "file": "metal/impactMetal_medium_001"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "……ねえ、今の音。さっきから何回も聞こえるんだけど、シャッターが勝手に揺れてるっぽくない？",
        "voice": "v009d"
      },
      {
        "type": "wait",
        "sec": 6.73
      },
      {
        "type": "chat",
        "msg": "勝手に揺れるシャッター……",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "猫じゃね？",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "20年放置の村に猫おるか？",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "猫だったら逆に嬉しいんだけど。……てかスマホの電波ついにゼロになった。WiFiもないし。配信落ちたらごめんね。",
        "voice": "v009e"
      },
      {
        "type": "wait",
        "sec": 8.3
      },
      {
        "type": "chat",
        "msg": "え、電波ないのにどうやって配信してんの",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "モバイルルーター持ってきてるって言ってた",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "そうそう、ルーターのおかげでギリ繋がってる。でもアンテナ1本。切れたらTikTokのほうでアーカイブ上げるから待っててね。",
        "voice": "v009f"
      },
      {
        "type": "wait",
        "sec": 7.95
      },
      {
        "type": "chat",
        "msg": "ティックトックにもいるのか",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "マルチプラットフォーム配信者",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── 商店街ゲートへ向かう ──"
      },
      {
        "type": "set_viewers",
        "count": 5200
      },
      {
        "type": "say",
        "text": "あ、見えた見えた。商店街のゲート。……幸福通り？",
        "voice": "v010"
      },
      {
        "type": "wait",
        "sec": 6.6
      },
      {
        "type": "chat",
        "msg": "雰囲気やばくなってきた",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "say",
        "text": "……なんか急に風止まったんだけど。さっきまで髪バサバサだったのに。静かすぎて自分の心臓の音聞こえる。",
        "voice": "v010a"
      },
      {
        "type": "wait",
        "sec": 7.74
      },
      {
        "type": "chat",
        "msg": "空気変わった…",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "霧がどんどん濃くなってない？",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "ほんとだ、霧やば。3メートル先見えないんだけど。……てかこれ映像的に映えるから逆にありがたい。サムネこれにしよ。",
        "voice": "v010b"
      },
      {
        "type": "wait",
        "sec": 8.52
      },
      {
        "type": "chat",
        "msg": "この状況でサムネの心配ｗｗ",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "配信者の鑑",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "いや帰れよ",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── 三択：トイレに向かう動機 ──"
      },
      {
        "type": "choice",
        "title": "▼  あ な た の 覚 悟  ▼",
        "prompt": "……この先にみゆきちゃんが殺されたトイレがある。どうする？",
        "choices": [
          {
            "text": "怖いけど……約束したし。行こう。",
            "sub": ""
          },
          {
            "text": "同接伸びてるし、ここで引いたら終わりでしょ。",
            "sub": ""
          },
          {
            "text": "トイレ凸って泣いてる女配信者とか最高にバズるじゃん。行くっしょ。",
            "sub": ""
          }
        ],
        "targets": [
          "choice_serious",
          "choice_ambition",
          "choice_clout"
        ]
      },
      {
        "type": "_comment",
        "_": "── 選択肢A：覚悟（恐怖を飲み込む・おばあちゃんとの約束） ──"
      },
      {
        "type": "label",
        "name": "choice_serious"
      },
      {
        "type": "say",
        "text": "……おばあちゃんがくれたお札、ちゃんと持ってる。みゆきちゃんのこと、ちゃんと見届けなきゃ。",
        "reading": "……おばあちゃんがくれたおふだ、ちゃんと持ってる。みゆきちゃんのこと、ちゃんと見届けなきゃ。",
        "voice": "v010c"
      },
      {
        "type": "wait",
        "sec": 5.93
      },
      {
        "type": "chat",
        "msg": "急に真面目になった",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "こういうとこだけちゃんとしてるの好き",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "見届けるってなに…？",
        "user": "はじめまして民"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "goto",
        "label": "after_choice"
      },
      {
        "type": "_comment",
        "_": "── 選択肢B：野心（数字に取り憑かれ始めている） ──"
      },
      {
        "type": "label",
        "name": "choice_ambition"
      },
      {
        "type": "say",
        "text": "ここで帰ったら、ただの『途中で逃げた女』だよ。……あたしは最後まで撮る。それがコンテンツだから。",
        "voice": "v010d"
      },
      {
        "type": "wait",
        "sec": 6.91
      },
      {
        "type": "chat",
        "msg": "逃げた女ｗｗｗ自分で言うなｗｗ",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "同接で判断するの草すぎる",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "数字に支配されてて好き",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "goto",
        "label": "after_choice"
      },
      {
        "type": "_comment",
        "_": "── 選択肢C：承認欲求の暴走（倫理観が壊れかけている） ──"
      },
      {
        "type": "label",
        "name": "choice_clout"
      },
      {
        "type": "say",
        "text": "心霊トイレで絶叫してる女ストリーマーとか、切り抜きだけで100万再生いくっしょ。……あたしの時代来たわ。",
        "voice": "v010e"
      },
      {
        "type": "wait",
        "sec": 7.38
      },
      {
        "type": "chat",
        "msg": "人が死んだ場所で再生数の話すんな",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "みゆきちゃんの前でそれ言えんの？",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "こいつやべえ…でも目が離せない",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── 合流 ──"
      },
      {
        "type": "label",
        "name": "after_choice"
      },
      {
        "type": "pos_x_await",
        "id": "walk_main"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "set_viewers",
        "count": 8420
      },
      {
        "type": "say",
        "text": "同接8000超えてる！ みんなありがとー！ ……よし、トイレ行くよ。ここからが本番！",
        "reading": "どうせつ8000超えてる！ みんなありがとー！ ……よし、トイレ行くよ。ここからが本番！",
        "voice": "v011"
      },
      {
        "type": "wait",
        "sec": 6.33
      },
      {
        "type": "chat",
        "msg": "本番きた！！",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "マジでやめとけ",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 1
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【シーン3：トイレ到着・みゆき遭遇】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "── 歩行方向(rot_y=-1.57/+X)から左90°=rot_y=0(-Z方向)で商店街を見上げる ──"
      },
      {
        "type": "rot_y",
        "target": 0,
        "dur": 1.5
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "head_x",
        "target": 0.6,
        "dur": 1.5
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "fade_black",
        "dur": 1
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "say_clear"
      },
      {
        "type": "head_x",
        "target": 0,
        "dur": 0.01
      },
      {
        "type": "rot_y",
        "target": 0,
        "dur": 0.01
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【CP1-2 stage_swap 境界：商店街パート開始】"
      },
      {
        "type": "fade_black",
        "dur": 0.5
      },
      {
        "type": "stage_swap",
        "scene": "res://scenes/Stage_Village.tscn",
        "spawn": [
          0,
          1,
          -28
        ]
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【シーン3A：商店街〜トイレ発見（暗転＋音響＋紙芝居ハイブリッド）】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "── ① 暗転中：足音だけが響く導入 ──"
      },
      {
        "type": "set_viewers",
        "count": 9200
      },
      {
        "type": "wait",
        "sec": 1
      },
      {
        "type": "sfx",
        "file": "door/creak2"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "画面真っ暗なんだが",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "足音だけ聞こえる……",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "say",
        "text": "ごめん、商店街のアーケード入ったら真っ暗で何も映んない。懐中電灯つけるね。",
        "voice": "v011a"
      },
      {
        "type": "wait",
        "sec": 5.92
      },
      {
        "type": "_comment",
        "_": "── ② 懐中電灯ON → 商店街画像表示（薄暗い懐中電灯風） ──"
      },
      {
        "type": "flashlight_on"
      },
      {
        "type": "bg_image",
        "file": "syouten.png",
        "dur": 2.0,
        "brightness": 0.3,
        "radius": 0.2,
        "softness": 0.3,
        "center": [
          0.4,
          0.5
        ]
      },
      {
        "type": "bg_walk_start",
        "speed": 1.0,
        "zoom_end": 1.5,
        "zoom_dur": 35.0,
        "radius": 0.2,
        "softness": 0.3
      },
      {
        "type": "fade_clear",
        "dur": 2.0,
        "target": 0.82
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "chat",
        "msg": "おっ見えてきた",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "暗すぎて全然わかんないw",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "camera_shake",
        "intensity": 0.02,
        "dur": 1
      },
      {
        "type": "say",
        "text": "うわ……シャッターだらけ。全部錆びてる。20年間、誰も来てないんだ。",
        "voice": "v011b"
      },
      {
        "type": "wait",
        "sec": 5.52
      },
      {
        "type": "chat",
        "msg": "廃墟感やばい",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "看板が落ちかけてる…",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "『きりはら食堂』って読める",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "ほんとだ。メニュー表がまだ貼ってある……カレー380円。なんか、時間が止まってるみたい。",
        "voice": "v011c"
      },
      {
        "type": "wait",
        "sec": 6.98
      },
      {
        "type": "_comment",
        "_": "── ③ 不審な金属音（ホラー第1波）→ 懐中電灯が一瞬揺れる ──"
      },
      {
        "type": "sfx",
        "file": "metal/impactMetal_heavy_002"
      },
      {
        "type": "flashlight_flicker"
      },
      {
        "type": "fade_black",
        "dur": 0.3,
        "target": 0.92
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "say",
        "text": "……ん？ 今なんか聞こえなかった？ 金属がぶつかるような……。",
        "voice": "v011d"
      },
      {
        "type": "wait",
        "sec": 4.69
      },
      {
        "type": "fade_clear",
        "dur": 1.5,
        "target": 0.82
      },
      {
        "type": "chat",
        "msg": "聞こえた。奥のほうから",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "シャッターが風で揺れただけだろ",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "いや風ないって言ってたやん…",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "sfx",
        "file": "metal/impactMetal_heavy_001"
      },
      {
        "type": "flashlight_flicker"
      },
      {
        "type": "horror_glitch",
        "dur": 0.12
      },
      {
        "type": "fade_black",
        "dur": 0.15,
        "target": 0.95
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "また鳴った！！ 懐中電灯もやばい！",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "……気のせいだよね。こういうの気にしてたら配信にならないし。進もう。",
        "voice": "v011e"
      },
      {
        "type": "wait",
        "sec": 5.09
      },
      {
        "type": "fade_clear",
        "dur": 1.0,
        "target": 0.82
      },
      {
        "type": "_comment",
        "_": "── ④ 同接上昇＋スパチャ（テンション回復） ──"
      },
      {
        "type": "set_viewers",
        "count": 11500
      },
      {
        "type": "chat",
        "msg": "同接1万超えてるぞ！",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "superchat",
        "msg": "怖すぎるけど応援！ 無事に帰ってきて！",
        "user": "こわがりペンギン",
        "amount": 500
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "スパチャありがとー！ 大丈夫、お札あるから。……多分。",
        "voice": "v011f"
      },
      {
        "type": "wait",
        "sec": 4.11
      },
      {
        "type": "_comment",
        "_": "── ⑤ 懐中電灯の異常（ホラー第2波）→ 画面も連動して暗くなる ──"
      },
      {
        "type": "sfx",
        "file": "door/creak1"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "flashlight_flicker"
      },
      {
        "type": "fade_black",
        "dur": 0.4,
        "target": 0.93
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "sfx",
        "file": "door/creak3"
      },
      {
        "type": "fade_clear",
        "dur": 0.8,
        "target": 0.85
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "bg_image_flicker",
        "dur": 4.5,
        "brightness": 0.3
      },
      {
        "type": "say",
        "text": "……懐中電灯チカチカしてる。電池じゃないよね、これ。なんか嫌な感じ。",
        "voice": "v011g"
      },
      {
        "type": "wait",
        "sec": 5.28
      },
      {
        "type": "chat",
        "msg": "電池じゃなくてソレは……",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "近くにいるんだよ、何かが",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "しゅっちの後ろ！！",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "flashlight_flicker"
      },
      {
        "type": "camera_shake",
        "intensity": 0.04,
        "dur": 0.5
      },
      {
        "type": "fade_black",
        "dur": 0.2,
        "target": 0.95
      },
      {
        "type": "say",
        "text": "え、後ろ！？ ……何もいないじゃん！ やめてよそういうの！ 心臓止まるかと思った！",
        "voice": "v011h"
      },
      {
        "type": "wait",
        "sec": 6.01
      },
      {
        "type": "fade_clear",
        "dur": 1.5,
        "target": 0.82
      },
      {
        "type": "chat",
        "msg": "ｗｗｗｗ",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.2
      },
      {
        "type": "chat",
        "msg": "いやマジで見えた気がしたんだけど",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── ⑥ トイレ発見（懐中電灯OFF→背景画像消去→完全暗転→一瞬だけ映す） ──"
      },
      {
        "type": "bg_walk_stop"
      },
      {
        "type": "flashlight_off"
      },
      {
        "type": "bg_image_clear",
        "dur": 0.5
      },
      {
        "type": "fade_black",
        "dur": 0.8
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "say",
        "text": "……あった。商店街の突き当たり。あの建物……。",
        "voice": "v011i"
      },
      {
        "type": "wait",
        "sec": 4.14
      },
      {
        "type": "scare_flash",
        "dur": 0.08
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "今一瞬映った！",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "トイレだ……ボロボロじゃん",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "入り口に何か貼ってあった",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "bg_image",
        "file": "toilet.jpg",
        "dur": 1.5,
        "brightness": 0.35
      },
      {
        "type": "say",
        "text": "公衆トイレだ。ここでみゆきちゃんが首を……。ドアに『使用禁止』って張り紙がある。",
        "reading": "公衆トイレだ。ここでみゆきちゃんがくびを……。ドアに『使用禁止』って張り紙がある。",
        "voice": "v011j"
      },
      {
        "type": "wait",
        "sec": 5.93
      },
      {
        "type": "bg_image_clear",
        "dur": 1.0
      },
      {
        "type": "_comment",
        "_": "── ⑦ 赤い文字の発見（ホラー第3波） ──"
      },
      {
        "type": "horror_tint",
        "color": [
          0.2,
          0,
          0
        ],
        "dur": 3
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "……その下に赤い文字で何か書いてある。『か……え……し……て』……。",
        "voice": "v011k"
      },
      {
        "type": "wait",
        "sec": 5.66
      },
      {
        "type": "scare_flash",
        "color": "red"
      },
      {
        "type": "sfx",
        "file": "bell/impactBell_heavy_000",
        "vol": 0
      },
      {
        "type": "sfx",
        "sound": "monster_growl",
        "vol": -8
      },
      {
        "type": "camera_shake",
        "intensity": 0.08,
        "dur": 1.5
      },
      {
        "type": "horror_glitch",
        "intensity": 8,
        "count": 3
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "sfx",
        "file": "door/creak1",
        "vol": -4
      },
      {
        "type": "sfx",
        "file": "metal/impactMetal_heavy_000",
        "vol": -3
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "chat",
        "msg": "かえして……？",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "何を返せって言ってんだ",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "首だろ……",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "帰れマジで帰れ",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "superchat",
        "msg": "お札1枚使って確認しよう",
        "user": "幽霊ガチ勢",
        "amount": 1000
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "horror_tint_clear",
        "dur": 2
      },
      {
        "type": "wait",
        "sec": 1
      },
      {
        "type": "say",
        "text": "お札はまだ使わない。3枚しかないんだから。……でも同接1万超えてるし。ここで引き返すわけにはいかないでしょ。",
        "reading": "お札はまだ使わない。3枚しかないんだから。……でもどうせつ1万超えてるし。ここで引き返すわけにはいかないでしょ。",
        "voice": "v011l"
      },
      {
        "type": "wait",
        "sec": 8.15
      },
      {
        "type": "_comment",
        "_": "── ⑧ トイレ突入（最終盛り上がり→暗転遷移） ──"
      },
      {
        "type": "set_viewers",
        "count": 14800
      },
      {
        "type": "chat",
        "msg": "同接もうすぐ1.5万！ 神回確定",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "入るなって言ってんのに……",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "よし、入るよ。みんな、ちゃんと見ててね。……お札握りしめて……。",
        "voice": "v011m"
      },
      {
        "type": "wait",
        "sec": 5.52
      },
      {
        "type": "sfx",
        "file": "metal/metalLatch"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "sfx",
        "file": "door/doorOpen_1"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "sfx",
        "file": "door/creak3"
      },
      {
        "type": "camera_shake",
        "intensity": 0.03,
        "dur": 1
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "horror_glitch",
        "dur": 0.2
      },
      {
        "type": "sfx",
        "file": "door/creak1"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "chat",
        "msg": "開いた……",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "中真っ暗じゃん",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "なんか臭いって絶対",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "……すっごい錆の匂い。水が腐った匂いも混じってる。……行くよ。",
        "voice": "v011n"
      },
      {
        "type": "wait",
        "sec": 5.14
      },
      {
        "type": "sfx",
        "file": "door/doorClose_3"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "fade_black",
        "dur": 1.5
      },
      {
        "type": "wait",
        "sec": 2
      },
      {
        "type": "say_clear"
      },
      {
        "type": "stage_swap",
        "scene": "res://scenes/PublicToiletStage.tscn",
        "spawn": [
          -1.5,
          0,
          -3.75
        ]
      },
      {
        "type": "_comment",
        "_": "══════════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "══ トイレ突入 — ホラー演出強化版 ══"
      },
      {
        "type": "_comment",
        "_": "══════════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "── 暗転中に向き設定（トイレ内部+Z方向） ──"
      },
      {
        "type": "rot_y",
        "target": 3.14,
        "dur": 0.01
      },
      {
        "type": "head_x",
        "target": 0,
        "dur": 0.01
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "══ トイレ入口 — 恐る恐る見渡し、ゆっくり近づく ══"
      },
      {
        "type": "_comment",
        "_": "── 超ゆっくり暗転解除（目が暗闇に慣れていく） ──"
      },
      {
        "type": "flashlight_on"
      },
      {
        "type": "fade_clear",
        "dur": 3.0
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "_comment",
        "_": "── 正面を見ている（暗くて不安） ──"
      },
      {
        "type": "head_x",
        "target": 0.0,
        "dur": 0.01
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "_comment",
        "_": "── 奥から反響する金属音（何かがいる？） ──"
      },
      {
        "type": "sfx",
        "file": "metal/impactMetal_medium_002",
        "vol": -22
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "_comment",
        "_": "── びくっとして少し見回す ──"
      },
      {
        "type": "head_x",
        "target": 0.05,
        "dur": 0.6
      },
      {
        "type": "wait",
        "sec": 0.6
      },
      {
        "type": "say",
        "text": "……ッ！",
        "voice": "v011r"
      },
      {
        "type": "camera_shake",
        "intensity": 0.01,
        "dur": 0.3
      },
      {
        "type": "wait",
        "sec": 1.14
      },
      {
        "type": "say_clear"
      },
      {
        "type": "wait",
        "sec": 0.6
      },
      {
        "type": "say",
        "text": "……なに今の音",
        "voice": "v011o"
      },
      {
        "type": "wait",
        "sec": 1.4
      },
      {
        "type": "say_clear"
      },
      {
        "type": "_comment",
        "_": "── 懐中電灯が不安定に点灯 ──"
      },
      {
        "type": "flashlight_flicker"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "うわ暗っ",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "なんか見える？",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "_comment",
        "_": "── おそるおそる左を見る（ゆっくり、ためらいながら） ──"
      },
      {
        "type": "rot_y",
        "target": 2.5,
        "dur": 2.0
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "_comment",
        "_": "── 左の壁…何もない。間を置く ──"
      },
      {
        "type": "wait",
        "sec": 1.2
      },
      {
        "type": "say",
        "text": "……大丈夫、なんもない……",
        "voice": "v011p"
      },
      {
        "type": "wait",
        "sec": 2.54
      },
      {
        "type": "say_clear"
      },
      {
        "type": "_comment",
        "_": "── 右をゆっくり見る ──"
      },
      {
        "type": "rot_y",
        "target": 3.8,
        "dur": 2.5
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "_comment",
        "_": "── 右の奥…個室のドアがうっすら見える ──"
      },
      {
        "type": "sfx",
        "file": "door/creak1",
        "vol": -20
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "chat",
        "msg": "今きしんだ？",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "気のせいだろ…",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "_comment",
        "_": "── 正面に戻す ──"
      },
      {
        "type": "rot_y",
        "target": 3.14,
        "dur": 1.5
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "_comment",
        "_": "── 覚悟を決めて一歩踏み出す（超ゆっくり） ──"
      },
      {
        "type": "say",
        "text": "……行くよ",
        "voice": "v011q"
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_z",
        "target": -2.5,
        "dur": 3.0,
        "id": "walk_step1"
      },
      {
        "type": "wait",
        "sec": 1.15
      },
      {
        "type": "say_clear"
      },
      {
        "type": "chat",
        "msg": "きたきたきた！！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.6
      },
      {
        "type": "vhs_glitch",
        "intensity": 1.2,
        "dur": 0.3
      },
      {
        "type": "pos_z_await",
        "id": "walk_step1"
      },
      {
        "type": "_comment",
        "_": "── 途中で立ち止まる（奥で何か音がした） ──"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "sfx",
        "file": "metal/metalClick",
        "vol": -14
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "……ッ！",
        "voice": "v011r"
      },
      {
        "type": "camera_shake",
        "intensity": 0.01,
        "dur": 0.3
      },
      {
        "type": "wait",
        "sec": 1.14
      },
      {
        "type": "say_clear"
      },
      {
        "type": "chat",
        "msg": "今音しなかった？",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "水道の音じゃね",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 1.2
      },
      {
        "type": "_comment",
        "_": "── 深呼吸して再び歩き始める ──"
      },
      {
        "type": "say",
        "text": "ここが噂の首切りトイレだよ。２番目の真ん中の個室、開けてみるね……。",
        "reading": "ここが噂のくびきりトイレだよ。２番目の真ん中の個室、開けてみるね……。",
        "voice": "v012"
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_z",
        "target": -0.75,
        "dur": 3.5,
        "id": "walk_step2"
      },
      {
        "type": "wait",
        "sec": 5.68
      },
      {
        "type": "chat",
        "msg": "ここ首切りのとこじゃん",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.6
      },
      {
        "type": "vhs_glitch",
        "intensity": 1.8,
        "dur": 0.4
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "sfx",
        "file": "metal/impactMetal_heavy_003",
        "vol": -18
      },
      {
        "type": "pos_z_await",
        "id": "walk_step2"
      },
      {
        "type": "_comment",
        "_": "── 到着。息を整えて…少し見上げる ──"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "head_x",
        "target": 0.15,
        "dur": 1.0
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── ベルの音…嫌な予感 ──"
      },
      {
        "type": "sfx",
        "file": "bell/impactBell_heavy_002",
        "vol": -18
      },
      {
        "type": "vhs_glitch",
        "intensity": 2.0,
        "dur": 0.3
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── 恐る恐る個室の方を向く（右に90度、最短回転） ──"
      },
      {
        "type": "head_x",
        "target": 0,
        "dur": 0.5
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "rot_y",
        "target": 4.71,
        "dur": 1.8
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "_comment",
        "_": "── 個室のドアが見える。懐中電灯がチカチカ ──"
      },
      {
        "type": "flashlight_flicker"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "投げ銭いくぞおおお",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "一万いけいけ！",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "_comment",
        "_": "── おひねりが飛び交い、同接が2万を超える ──"
      },
      {
        "type": "superchat",
        "user": "ゴーストハンター",
        "amount": 5000,
        "msg": "開けろ開けろ開けろ！！"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "superchat",
        "user": "幽霊ガチ勢",
        "amount": 3000,
        "msg": "みゆきちゃんに会いたい"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "set_viewers",
        "count": 14200
      },
      {
        "type": "superchat",
        "user": "配信民99",
        "amount": 2000,
        "msg": "ガチ連打させろ！！"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "同接1万超えてるぞ",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "set_viewers",
        "count": 20100
      },
      {
        "type": "chat",
        "msg": "2万突破ｗｗｗ",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "トレンド入りしてる",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "_comment",
        "_": "── Kの不穏なチャット（低頻度・初出） ──"
      },
      {
        "type": "chat",
        "msg": "開けないほうがいい",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "sfx",
        "file": "door/creak2",
        "vol": -16
      },
      {
        "type": "horror_glitch",
        "intensity": 1.5,
        "count": 1
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "chat",
        "msg": "今の何！？",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.2
      },
      {
        "type": "chat",
        "msg": "画面乱れたぞ",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.15
      },
      {
        "type": "chat",
        "msg": "ノイズ走ったな",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.15
      },
      {
        "type": "chat",
        "msg": "電波悪い？",
        "user": "名無しさん"
      },
      {
        "type": "_comment",
        "_": "══ フェーズ3-2：個室へ歩いて開ける ══"
      },
      {
        "type": "say",
        "text": "マジか！ みんなスパチャサンキュー！ じゃあ……開けるよ？ せーの！",
        "voice": "v013"
      },
      {
        "type": "wait",
        "sec": 4.81
      },
      {
        "type": "_comment",
        "_": "── 個室に向かって歩く ──"
      },
      {
        "type": "pos_x",
        "target": 1.0,
        "dur": 4.0,
        "id": "walk_to_stall"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── 歩行中にドアの奥から軋み音 ──"
      },
      {
        "type": "sfx",
        "file": "door/creak1",
        "vol": -10
      },
      {
        "type": "camera_shake",
        "intensity": 0.015,
        "dur": 0.3
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "pos_x_await",
        "id": "walk_to_stall"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "_comment",
        "_": "── 個室の前。手を伸ばす（少し見下ろす） ──"
      },
      {
        "type": "head_x",
        "target": -0.1,
        "dur": 0.5
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "sfx",
        "file": "metal/metalLatch",
        "vol": -6
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "_comment",
        "_": "── 扉を開ける ──"
      },
      {
        "type": "sfx",
        "sound": "door_creak"
      },
      {
        "type": "head_x",
        "target": 0,
        "dur": 0.4
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "_comment",
        "_": "── 個室の扉を開ける。誰もいない。古びた和式便器があるだけ ──"
      },
      {
        "type": "wait",
        "sec": 2
      },
      {
        "type": "chat",
        "msg": "何もないじゃん",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "ただのトイレで草",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "══ フェーズ3-3：偽りの安心（指定セリフ） ══"
      },
      {
        "type": "say",
        "text": "……え、嘘。誰もいないじゃん。期待させてごめ……ん？",
        "voice": "v014"
      },
      {
        "type": "wait",
        "sec": 4.43
      },
      {
        "type": "chat",
        "msg": "ん？",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "最後のなんだ？",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "今の何？",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 1
      },
      {
        "type": "_comment",
        "_": "══ フェーズ3-4：天井のみゆき発見（指定セリフ） ══"
      },
      {
        "type": "_comment",
        "_": "── しゅっちがカメラを天井に向ける ──"
      },
      {
        "type": "head_x",
        "target": 0.15,
        "dur": 1
      },
      {
        "type": "wait",
        "sec": 1
      },
      {
        "type": "horror_glitch",
        "intensity": 2,
        "count": 1
      },
      {
        "type": "head_x",
        "target": 0.35,
        "dur": 1.2
      },
      {
        "type": "wait",
        "sec": 1.2
      },
      {
        "type": "chat",
        "msg": "今ノイズ入った？",
        "user": "おばけ見たい"
      },
      {
        "type": "wait",
        "sec": 0.15
      },
      {
        "type": "chat",
        "msg": "え、カメラバグってない？",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.12
      },
      {
        "type": "chat",
        "msg": "天井……何かいる？",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.1
      },
      {
        "type": "chat",
        "msg": "上見て！！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "flashlight_flicker"
      },
      {
        "type": "horror_glitch",
        "intensity": 3,
        "count": 1
      },
      {
        "type": "head_x",
        "target": 0.55,
        "dur": 1.3
      },
      {
        "type": "wait",
        "sec": 1.3
      },
      {
        "type": "horror_tint"
      },
      {
        "type": "head_x",
        "target": 0.7,
        "dur": 1
      },
      {
        "type": "wait",
        "sec": 1
      },
      {
        "type": "_comment",
        "_": "── 天井に逆さまの直立不動ポーズで貼り付いたみゆきが映り込む ──"
      },
      {
        "type": "miyuki_spawn",
        "pos": [
          2.5,
          3.0,
          -0.75
        ],
        "upside_down": true,
        "scale": 1.5,
        "light_energy": 2.5,
        "light_range": 5.0,
        "visible": false,
        "_note": "プレイヤー正面(+X)の天井 — X=1.0,Z=-0.75の1.5m前方、Y=3.0天井"
      },
      {
        "type": "horror_glitch",
        "intensity": 5,
        "count": 2
      },
      {
        "type": "miyuki_move",
        "visible": true,
        "_note": "グリッチノイズの隙に姿が見える"
      },
      {
        "type": "sfx",
        "sound": "monster_growl",
        "vol": -18
      },
      {
        "type": "_comment",
        "_": "══ みゆき発見！ 画面ホラーレッド＋チャット欄恐怖演出 ══"
      },
      {
        "type": "horror_red",
        "dur": 18
      },
      {
        "type": "chat_horror_mode",
        "dur": 18
      },
      {
        "type": "scare_flash",
        "color": "red"
      },
      {
        "type": "sfx",
        "file": "bell/impactBell_heavy_000",
        "vol": -8
      },
      {
        "type": "camera_shake",
        "intensity": 0.04,
        "dur": 0.6
      },
      {
        "type": "set_viewers",
        "count": 28500
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "……待って。何あれ。天井になんか……ポーズ決めて固まってるやつがいる。……え、スマホを外すといないのに、画面で見るとそこにいるの！？",
        "voice": "v015"
      },
      {
        "type": "wait",
        "sec": 8.01
      },
      {
        "type": "chat",
        "msg": "ウソだろ！？！？",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.1
      },
      {
        "type": "chat",
        "msg": "天井に人いる！！！！",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.1
      },
      {
        "type": "chat",
        "msg": "は？？？？",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.08
      },
      {
        "type": "chat",
        "msg": "首がない…首がない…",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.1
      },
      {
        "type": "chat",
        "msg": "逆さまってどういうことだよ",
        "user": "おばけ見たい"
      },
      {
        "type": "wait",
        "sec": 0.08
      },
      {
        "type": "chat",
        "msg": "カメラ外すと消えるってやばいだろ",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.1
      },
      {
        "type": "chat",
        "msg": "通報した方がいい",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.08
      },
      {
        "type": "chat",
        "msg": "逃げて！！！！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.08
      },
      {
        "type": "chat",
        "msg": "ガチじゃん……ガチじゃん……",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.12
      },
      {
        "type": "chat",
        "msg": "見えてる",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.1
      },
      {
        "type": "chat",
        "msg": "ずっと見てた",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.08
      },
      {
        "type": "chat",
        "msg": "おいで",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 1.2
      },
      {
        "type": "_comment",
        "_": "══ フェーズ3-5：みゆき接近・扉が開かない（指定セリフ） ══"
      },
      {
        "type": "_comment",
        "_": "── ノイズの隙にみゆきが天井→床→背後へワープ ──"
      },
      {
        "type": "miyuki_move",
        "pos": [
          1.0,
          0.0,
          -2.5
        ],
        "upside_down": false,
        "light_energy": 6.0,
        "_note": "天井から床にワープ — 通常サイズ感のまま接近"
      },
      {
        "type": "horror_glitch",
        "intensity": 10,
        "count": 4
      },
      {
        "type": "scare_flash",
        "color": "white"
      },
      {
        "type": "sfx",
        "sound": "monster_growl",
        "vol": -6
      },
      {
        "type": "chat",
        "msg": "え、消えた！？",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.06
      },
      {
        "type": "chat",
        "msg": "どこいった！？！？",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.06
      },
      {
        "type": "chat",
        "msg": "ワープした！？",
        "user": "おばけ見たい"
      },
      {
        "type": "wait",
        "sec": 0.06
      },
      {
        "type": "chat",
        "msg": "後ろ！後ろ！後ろ！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.06
      },
      {
        "type": "chat",
        "msg": "逃げろおおおお",
        "user": "ガクブル太郎"
      },
      {
        "type": "miyuki_move",
        "track_player": true,
        "walk": true,
        "convulsion_intensity": 0.3,
        "light_energy": 8.0,
        "_note": "みゆきがプレイヤーを追跡開始 — 背後からゆっくり接近"
      },
      {
        "type": "head_x",
        "target": 0.3,
        "dur": 0.06
      },
      {
        "type": "sleep",
        "sec": 0.07
      },
      {
        "type": "head_x",
        "target": -0.1,
        "dur": 0.06
      },
      {
        "type": "sleep",
        "sec": 0.07
      },
      {
        "type": "head_x",
        "target": 0.15,
        "dur": 0.07
      },
      {
        "type": "sleep",
        "sec": 0.08
      },
      {
        "type": "head_x",
        "target": 0,
        "dur": 0.1
      },
      {
        "type": "sleep",
        "sec": 0.1
      },
      {
        "type": "horror_glitch",
        "intensity": 8,
        "count": 3
      },
      {
        "type": "flashlight_flicker"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "うしろ",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.12
      },
      {
        "type": "chat",
        "msg": "くる",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.12
      },
      {
        "type": "chat",
        "msg": "うしろ",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.1
      },
      {
        "type": "chat",
        "msg": "逃げて",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.1
      },
      {
        "type": "chat",
        "msg": "うしろ",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.1
      },
      {
        "type": "chat",
        "msg": "うしろ",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "set_viewers",
        "count": 35800
      },
      {
        "type": "sfx",
        "sound": "door_creak"
      },
      {
        "type": "horror_glitch",
        "intensity": 12,
        "count": 5
      },
      {
        "type": "horror_flash",
        "dur": 0.4
      },
      {
        "type": "head_x",
        "target": 0.12,
        "dur": 0.06
      },
      {
        "type": "sleep",
        "sec": 0.07
      },
      {
        "type": "head_x",
        "target": -0.08,
        "dur": 0.06
      },
      {
        "type": "sleep",
        "sec": 0.07
      },
      {
        "type": "head_x",
        "target": 0.06,
        "dur": 0.07
      },
      {
        "type": "sleep",
        "sec": 0.07
      },
      {
        "type": "head_x",
        "target": 0,
        "dur": 0.1
      },
      {
        "type": "sleep",
        "sec": 0.1
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "ひっ……！？ こっち来た！ 扉が開かない！ 開けて、開けてよ！！",
        "voice": "v016"
      },
      {
        "type": "wait",
        "sec": 4.69
      },
      {
        "type": "chat",
        "msg": "ぎゃあああ！！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.2
      },
      {
        "type": "chat",
        "msg": "ドア開けろ！！！",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.2
      },
      {
        "type": "chat",
        "msg": "お札！！お札使え！！",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "さっきのお札！！！",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "逃げられない",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "_comment",
        "_": "══ フェーズ3-6：お札使用（指定セリフ） ══"
      },
      {
        "type": "_comment",
        "_": "── しゅっちはパニックになり、1枚目のお札を扉に叩きつける ──"
      },
      {
        "type": "horror_glitch",
        "intensity": 6,
        "count": 2
      },
      {
        "type": "sfx",
        "sound": "monster_growl",
        "vol": 2
      },
      {
        "type": "say",
        "text": "お札、頼む……！ お願い助けてよっ！！",
        "voice": "v017"
      },
      {
        "type": "wait",
        "sec": 3.33
      },
      {
        "type": "use_ofuda"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── 画面がホワイトアウト ──"
      },
      {
        "type": "scare_flash",
        "color": "red"
      },
      {
        "type": "horror_flash",
        "dur": 0.6
      },
      {
        "type": "horror_glitch",
        "intensity": 20,
        "count": 8
      },
      {
        "type": "head_x",
        "target": 0.25,
        "dur": 0.05
      },
      {
        "type": "sleep",
        "sec": 0.06
      },
      {
        "type": "head_x",
        "target": -0.18,
        "dur": 0.06
      },
      {
        "type": "sleep",
        "sec": 0.07
      },
      {
        "type": "head_x",
        "target": 0.14,
        "dur": 0.07
      },
      {
        "type": "sleep",
        "sec": 0.08
      },
      {
        "type": "head_x",
        "target": -0.09,
        "dur": 0.08
      },
      {
        "type": "sleep",
        "sec": 0.09
      },
      {
        "type": "head_x",
        "target": 0.05,
        "dur": 0.1
      },
      {
        "type": "sleep",
        "sec": 0.1
      },
      {
        "type": "head_x",
        "target": 0,
        "dur": 0.15
      },
      {
        "type": "sleep",
        "sec": 0.15
      },
      {
        "type": "scare_flash",
        "color": "white"
      },
      {
        "type": "horror_tint_clear"
      },
      {
        "type": "vhs_reset"
      },
      {
        "type": "wait",
        "sec": 1
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【シーン4：脱出 — トイレ内を来た道で戻る】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "── 個室から飛び出す（振り返って通路側へ） ──"
      },
      {
        "type": "sfx",
        "sound": "door_creak"
      },
      {
        "type": "rot_y",
        "target": 1.57,
        "dur": 0.3
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "_comment",
        "_": "── 個室から飛び出す。心臓バクバク演出開始 ──"
      },
      {
        "type": "sfx",
        "file": "door/doorClose_2",
        "vol": -4,
        "_note": "心臓の鼓動1（ドクン）"
      },
      {
        "type": "camera_shake",
        "intensity": 0.02,
        "dur": 0.15
      },
      {
        "type": "say",
        "text": "で、出れた…… もういや本当に出るなんて聞いてない！！",
        "voice": "v018"
      },
      {
        "type": "set_viewers",
        "count": 50200
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_x",
        "target": -1.5,
        "dur": 2.5,
        "id": "retreat_x"
      },
      {
        "type": "wait",
        "sec": 3.61
      },
      {
        "type": "sfx",
        "file": "door/doorClose_2",
        "vol": -6,
        "_note": "心臓の鼓動2"
      },
      {
        "type": "camera_shake",
        "intensity": 0.018,
        "dur": 0.12
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "sfx",
        "file": "door/doorClose_2",
        "vol": -5,
        "_note": "心臓の鼓動3"
      },
      {
        "type": "camera_shake",
        "intensity": 0.02,
        "dur": 0.12
      },
      {
        "type": "chat",
        "msg": "出れた！！！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.25
      },
      {
        "type": "chat",
        "msg": "お札すげえ！！",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.2
      },
      {
        "type": "chat",
        "msg": "走れ走れ走れ！！",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.6
      },
      {
        "type": "sfx",
        "file": "door/doorClose_2",
        "vol": -5,
        "_note": "心臓の鼓動4"
      },
      {
        "type": "camera_shake",
        "intensity": 0.022,
        "dur": 0.12
      },
      {
        "type": "pos_x_await",
        "id": "retreat_x"
      },
      {
        "type": "_comment",
        "_": "── 通路に出た。入口方向（-Z）を向く ──"
      },
      {
        "type": "rot_y",
        "target": 0,
        "dur": 0.5
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── 来た道を戻る（z=-0.75 → z=-3.75）心臓バクバク継続 ──"
      },
      {
        "type": "pos_z",
        "target": -3.75,
        "dur": 4.0,
        "id": "retreat_z"
      },
      {
        "type": "say",
        "text": "怖い怖い怖い怖い！！！",
        "voice": "v018b"
      },
      {
        "type": "wait",
        "sec": 1.7
      },
      {
        "type": "sfx",
        "file": "door/doorClose_2",
        "vol": -4,
        "_note": "心臓の鼓動5（加速）"
      },
      {
        "type": "camera_shake",
        "intensity": 0.025,
        "dur": 0.15
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "sfx",
        "file": "door/doorClose_2",
        "vol": -4,
        "_note": "心臓の鼓動6"
      },
      {
        "type": "camera_shake",
        "intensity": 0.025,
        "dur": 0.12
      },
      {
        "type": "chat",
        "msg": "もう帰れって！！",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "心臓止まるかと思った",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "sfx",
        "file": "door/doorClose_2",
        "vol": -5,
        "_note": "心臓の鼓動7（少し落ち着く）"
      },
      {
        "type": "camera_shake",
        "intensity": 0.018,
        "dur": 0.1
      },
      {
        "type": "wait",
        "sec": 0.6
      },
      {
        "type": "sfx",
        "file": "metal/impactMetal_heavy_002",
        "vol": -16,
        "_note": "背後で金属音（まだ安全じゃない感）"
      },
      {
        "type": "chat",
        "msg": "後ろから音した！？",
        "user": "おばけ見たい"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "sfx",
        "file": "door/doorClose_2",
        "vol": -6,
        "_note": "心臓の鼓動8（減速）"
      },
      {
        "type": "pos_z_await",
        "id": "retreat_z"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "_comment",
        "_": "── トイレ入口到着。心臓バクバク収まる ──"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "superchat",
        "user": "ゴーストハンター",
        "amount": 10000,
        "msg": "生きて帰れ！！！"
      },
      {
        "type": "say",
        "text": "…… スパチャありがと……さっきの天井の、首がなかった…… あれがみゆきちゃんなの？",
        "reading": "…… スパチャありがと……さっきの天井の、くびがなかった…… あれがみゆきちゃんなの？",
        "voice": "v018c"
      },
      {
        "type": "wait",
        "sec": 6.11
      },
      {
        "type": "chat",
        "msg": "マジで本物だったのか",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "お札すげえ……",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "逃がしたんじゃない",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "miyuki_move",
        "visible": false,
        "_note": "暗転前にみゆきを非表示"
      },
      {
        "type": "fade_black",
        "dur": 1.5
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "say_clear"
      },
      {
        "type": "_comment",
        "_": "── トイレ脱出：全ホラー演出をクリア ──"
      },
      {
        "type": "horror_tint_clear",
        "dur": 0.5
      },
      {
        "type": "horror_red_clear"
      },
      {
        "type": "chat_horror_clear"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【CP1-3：バス停へ逃走→コメ＆スパチャ煽り→反転→村の奥へ】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "── Phase1: stage_swap → 入口方向へ走る ──"
      },
      {
        "type": "miyuki_despawn",
        "_note": "トイレ脱出 — みゆきを消去"
      },
      {
        "type": "vhs_reset"
      },
      {
        "type": "stage_swap",
        "scene": "res://scenes/Stage_Village.tscn",
        "spawn": [
          25,
          1,
          4
        ]
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "rot_y",
        "target": 1.57,
        "dur": 0.01
      },
      {
        "type": "fade_clear",
        "dur": 1
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_x",
        "target": 15,
        "dur": 8,
        "id": "walk_escape"
      },
      {
        "type": "say",
        "text": "帰る帰る帰る……バス停まで戻る！ もう関わりたくない！",
        "voice": "v019"
      },
      {
        "type": "wait",
        "sec": 4.68
      },
      {
        "type": "chat",
        "msg": "走れ走れ走れ！！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "もう帰ろうマジで",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "set_viewers",
        "count": 52000
      },
      {
        "type": "chat",
        "msg": "同接5万超えてるぞ",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── Phase2: スパチャ煽り → 足が止まる ──"
      },
      {
        "type": "superchat",
        "user": "切り抜きch登録10万",
        "amount": 10000,
        "msg": "ここで帰ったら誰も覚えてないよ？"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "pos_x_await",
        "id": "walk_escape"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "……え？",
        "voice": "v020"
      },
      {
        "type": "wait",
        "sec": 1.35
      },
      {
        "type": "chat",
        "msg": "いや帰れよ",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "10万人の切り抜き師が言ってんぞ",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "superchat",
        "user": "深夜のまとめ師",
        "amount": 5000,
        "msg": "奥まで行ったら切り抜かせて 再生数えぐいことになる"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "chat",
        "msg": "金の力で人を動かすな",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "いけいけいけ！",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "set_viewers",
        "count": 55000
      },
      {
        "type": "chat",
        "msg": "5万5千きたあああ",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "say",
        "text": "……5万5千。あたしの配信で、5万5千人が見てる。",
        "voice": "v021"
      },
      {
        "type": "wait",
        "sec": 4.38
      },
      {
        "type": "_comment",
        "_": "── CP1-4 三択分岐 ──"
      },
      {
        "type": "label",
        "name": "cp4_choice"
      },
      {
        "type": "choice",
        "title": "▼  引 き 返 せ な い  ▼",
        "danger": true,
        "prompt": "どうする？",
        "choices": [
          {
            "text": "……奥に進む。この目で確かめる。",
            "sub": ""
          },
          {
            "text": "もう一回トイレを調べる。証拠を押さえたい。",
            "sub": ""
          },
          {
            "text": "……やっぱ帰る。無理。",
            "sub": "怖気づいてしまった"
          }
        ],
        "targets": [
          "cp4_continue",
          "cp4_continue",
          "cp4_bad_end"
        ]
      },
      {
        "type": "_comment",
        "_": "── バッドエンド分岐：逃げる ──"
      },
      {
        "type": "label",
        "name": "cp4_bad_end"
      },
      {
        "type": "_comment",
        "_": "── バッドエンド：逃走 → 配信終了 ──"
      },
      {
        "type": "chat",
        "msg": "え、帰るの？",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "ここまで来て！？",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "ごめん無理……！ さっきの天井のアレ思い出したら足震えてきた……！",
        "voice": "v024"
      },
      {
        "type": "wait",
        "sec": 5.0
      },
      {
        "type": "chat",
        "msg": "5万人の前で逃げんのかよ",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "superchat",
        "user": "ゴーストハンター",
        "amount": 5000,
        "msg": "逃げるな！！ スパチャ返せ！！"
      },
      {
        "type": "wait",
        "sec": 0.6
      },
      {
        "type": "say",
        "text": "スパチャは返せないけど命は返してほしい……！ ばいばい！",
        "voice": "v025"
      },
      {
        "type": "wait",
        "sec": 4.08
      },
      {
        "type": "chat",
        "msg": "草",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "配信者の鑑",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "生存ルートで草",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "_comment",
        "_": "── バッドエンド：配信終了 → 暗転 → エピローグ ──"
      },
      {
        "type": "_comment",
        "_": "── エンディング専用演出：ひきこもり ──"
      },
      {
        "type": "play_ending",
        "id": "bad_hikikomori",
        "ending_title": "ひきこもり",
        "sections": [
          {
            "title": "帰路",
            "mood": "cold",
            "lines": [
              {
                "text": "バス停で夜が明けるまで待った。",
                "voice": "res://assets/audio/voice/ch01/v026.wav",
                "voice_dur": 2.03,
                "pause": 3.0
              },
              {
                "text": "3時間。ずっと震えてた。",
                "voice": "res://assets/audio/voice/ch01/v027.wav",
                "voice_dur": 2.0,
                "pause": 3.0
              },
              {
                "text": "懐中電灯を抱きしめて、お札を握りしめて。",
                "voice": "res://assets/audio/voice/ch01/v028.wav",
                "voice_dur": 3.64,
                "pause": 4.6
              },
              {
                "text": "バスが来た時、泣いた。",
                "voice": "res://assets/audio/voice/ch01/v029.wav",
                "voice_dur": 1.94,
                "pause": 3.4,
                "emphasis": true
              }
            ],
            "wait": 2.5
          },
          {
            "title": "削除",
            "mood": "dark",
            "lines": [
              {
                "text": "家に帰って、アーカイブは全部消した。",
                "voice": "res://assets/audio/voice/ch01/v030.wav",
                "voice_dur": 2.81,
                "pause": 3.8
              },
              {
                "text": "5万5千人が見てたのに。",
                "voice": "res://assets/audio/voice/ch01/v031.wav",
                "voice_dur": 1.9,
                "pause": 2.9
              },
              {
                "text": "でも関係ない。あんなもの見ちゃったら、もう関係ない。",
                "voice": "res://assets/audio/voice/ch01/v032.wav",
                "voice_dur": 3.99,
                "pause": 5.5,
                "emphasis": true
              }
            ],
            "wait": 2.5
          },
          {
            "title": "天井",
            "mood": "fear",
            "lines": [
              {
                "text": "次の日から配信できなくなった。",
                "voice": "res://assets/audio/voice/ch01/v033.wav",
                "voice_dur": 2.41,
                "pause": 3.4
              },
              {
                "text": "パソコンの前に座ると、あの天井が見える。",
                "voice": "res://assets/audio/voice/ch01/v034.wav",
                "voice_dur": 3.12,
                "pause": 4.1
              },
              {
                "text": "首のない女の子が、こっちを見てる。",
                "voice": "res://assets/audio/voice/ch01/v035.wav",
                "voice_dur": 2.89,
                "pause": 4.4,
                "emphasis": true
              }
            ],
            "wait": 2.5
          },
          {
            "title": "閉鎖",
            "mood": "cold",
            "lines": [
              {
                "text": "1週間。2週間。1ヶ月。",
                "voice": "res://assets/audio/voice/ch01/v036.wav",
                "voice_dur": 2.85,
                "pause": 3.9
              },
              {
                "text": "気づいたら外に出られなくなってた。",
                "voice": "res://assets/audio/voice/ch01/v037.wav",
                "voice_dur": 2.56,
                "pause": 3.6
              },
              {
                "text": "カーテンも開けられない。スマホの通知も全部切った。",
                "voice": "res://assets/audio/voice/ch01/v038.wav",
                "voice_dur": 3.75,
                "pause": 4.8
              }
            ],
            "wait": 2.5
          },
          {
            "title": "沈黙",
            "image": "res://assets/textures/bad_end_hikikomori.png",
            "mood": "warm",
            "lines": [
              {
                "text": "お母さんがドアの向こうから呼んでる。",
                "voice": "res://assets/audio/voice/ch01/v039.wav",
                "voice_dur": 2.42,
                "pause": 3.4
              },
              {
                "text": "ごはんできたよって。",
                "voice": "res://assets/audio/voice/ch01/v040.wav",
                "voice_dur": 1.39,
                "pause": 2.4
              },
              {
                "text": "聞こえてるのに、返事ができない。",
                "voice": "res://assets/audio/voice/ch01/v041.wav",
                "voice_dur": 2.38,
                "pause": 3.4
              },
              {
                "text": "声の出し方、忘れちゃったのかな。",
                "voice": "res://assets/audio/voice/ch01/v042.wav",
                "voice_dur": 2.49,
                "pause": 4.0,
                "emphasis": true
              }
            ],
            "wait": 3.0
          },
          {
            "title": "",
            "image": "res://assets/textures/bad_end_hikikomori.png",
            "mood": "dark",
            "lines": [
              {
                "text": "布団の中は暗くてあったかい。",
                "voice": "res://assets/audio/voice/ch01/v043.wav",
                "voice_dur": 2.25,
                "pause": 3.2
              },
              {
                "text": "ここにいれば誰にも会わなくていい。天井も見なくていい。",
                "voice": "res://assets/audio/voice/ch01/v044.wav",
                "voice_dur": 3.98,
                "pause": 5.0
              },
              {
                "text": "でもたまに思うんだ。",
                "voice": "res://assets/audio/voice/ch01/v045.wav",
                "voice_dur": 1.42,
                "pause": 2.4
              },
              {
                "text": "あの時、逃げなかったら。",
                "voice": "res://assets/audio/voice/ch01/v046.wav",
                "voice_dur": 2.03,
                "pause": 3.5,
                "emphasis": true
              },
              {
                "text": "あたし、どうなってたんだろう。",
                "voice": "res://assets/audio/voice/ch01/v047.wav",
                "voice_dur": 2.03,
                "pause": 3.5,
                "emphasis": true
              }
            ],
            "wait": 4.0
          }
        ]
      },
      {
        "type": "bad_end",
        "title": "BAD END\n「ひきこもり」",
        "image": "res://assets/textures/bad_end_hikikomori.png",
        "return_label": "cp4_choice",
        "fade_dur": 0.5,
        "display_dur": 5.0
      },
      {
        "type": "_comment",
        "_": "── 正規ルート続行 ──"
      },
      {
        "type": "label",
        "name": "cp4_continue"
      },
      {
        "type": "chat",
        "msg": "目の色変わったぞこいつ",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "superchat",
        "user": "ゴーストハンター",
        "amount": 10000,
        "msg": "行けしゅっち！！ 廃村の奥見せてくれ！！"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "chat",
        "msg": "スパチャ止まんねえ",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "こいつ行く気だぞ",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "_comment",
        "_": "── Phase3: 反転（承認欲求に負ける） ──"
      },
      {
        "type": "say",
        "text": "……ごめん。帰れない。この数字見ちゃったら、もう止まれないよ。",
        "voice": "v022"
      },
      {
        "type": "wait",
        "sec": 4.51
      },
      {
        "type": "rot_y",
        "target": -1.57,
        "dur": 1.5
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "chat",
        "msg": "うわ振り返った",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.2
      },
      {
        "type": "chat",
        "msg": "承認欲求モンスター",
        "user": "名無しさん"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "いいぞ！！！！",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "おいで",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "_comment",
        "_": "── Phase4: 村の奥（+X方向ゲート）へ歩行 X=15→X=36 ──"
      },
      {
        "type": "set_viewers",
        "count": 58000
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_x",
        "target": 36,
        "dur": 12,
        "id": "walk_deep"
      },
      {
        "type": "say",
        "text": "お札残り2枚、バッテリー半分。……上等だよ。全部見せてあげる。",
        "voice": "v023"
      },
      {
        "type": "wait",
        "sec": 5.44
      },
      {
        "type": "chat",
        "msg": "かっけえ……",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "フラグにしか聞こえない",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "superchat",
        "user": "古参リスナー",
        "amount": 5000,
        "msg": "しゅっちならやれる 信じてる"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "スパチャで背中押すの草",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "6万いくぞこれ",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "set_viewers",
        "count": 60500
      },
      {
        "type": "wait",
        "sec": 3.0
      },
      {
        "type": "pos_x_await",
        "id": "walk_deep"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── ゲート到着（GOAL） ──"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "fade_black",
        "dur": 1
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "say_clear"
      }
    ],
    "_pv_spawn": {
      "x": 1.5,
      "z": 3
    }
  },
  "ch01_haison_souko": {
    "chapter": "ch01_haison_souko",
    "_note": "第1.5章：廃倉庫 ─ 保存された絶叫 ─",
    "events": [
      {
        "type": "set_viewers",
        "count": 52000
      },
      {
        "type": "flashlight_on"
      },
      {
        "type": "say",
        "text": "ハァ、ハァ……トイレからなんとか逃げた。……見て、あの建物。DMで言ってた『証拠의VHS』がある廃倉庫だ。配信的には、ここで証拠をゲットするのがセオリ―だよね。",
        "voice": "v101"
      },
      {
        "type": "wait",
        "sec": 4.5
      },
      {
        "type": "chat",
        "msg": "証拠ｗ",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "ガチの事件じゃん",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "早く入れよ",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "見ている",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "sfx",
        "sound": "door_creak"
      },
      {
        "type": "wait",
        "sec": 1.0
      }
    ]
  },
  "ch01_haison_souko_found": {
    "chapter": "ch01_haison_souko_found",
    "_note": "VHS発見時の演出",
    "events": [
      {
        "type": "say",
        "text": "うわ、カビ臭い……。あ、あった！ ラベルに『1994_10_記録』って書いてある。これ、私が生まれた年にみゆきちゃんが……。",
        "voice": "v102"
      },
      {
        "type": "wait",
        "sec": 6.0
      },
      {
        "type": "_comment",
        "_": "── 演出：モニターが勝手に起動 ──"
      },
      {
        "type": "sfx",
        "sound": "static_noise"
      },
      {
        "type": "vhs_glitch",
        "intensity": 2.0,
        "dur": 1.5
      },
      {
        "type": "say",
        "text": "これ、私！？ なんで30年前のビデオに『今の私』が映ってるの！？ やだ、消して！ 消してよ！！",
        "voice": "v103"
      },
      {
        "type": "wait",
        "sec": 5.5
      },
      {
        "type": "set_viewers",
        "count": 78000
      },
      {
        "type": "say",
        "text": "……これで世界が変わる。でも、これをどこかで流さなきゃ。……神社！ 神社なら上映できる場所があるはず！！",
        "voice": "v104"
      },
      {
        "type": "wait",
        "sec": 6.5
      },
      {
        "type": "fade_black",
        "dur": 1.0
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "say_clear"
      },
      {
        "type": "fade_clear",
        "dur": 1.5
      }
    ]
  },
  "ch02_haison_naibu": {
    "chapter": "ch02_haison_naibu",
    "_note": "CP2 廃村内部 — 自動歩行: 南入口→廃屋(人形)→掲示板(新聞)→中央広場(スマホ山・K初登場)",
    "events": [
      {
        "type": "say",
        "text": "神社の門、鍵がかかってる……。奥の民家で儀式の道具を見つけないと。……あれ？ なにこれ、画面に変なゲージが出てる。……身体、重い。なんか、動くのが……しんどい……",
        "voice": "v301"
      },
      {
        "type": "wait",
        "sec": 6.5
      },
      {
        "type": "chat",
        "msg": "しゅっち、ラグいぞｗ",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "動きがカクカクしててキモい",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "案山子みたいだなｗ",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "身体が……一歩出すのに、時間がかかる。みゆきに見られてると、どんどん自分が固まっていくみたい……。やだ、案山子になりたくない！ 10fps……3fps……動け……動けよ私の足！",
        "voice": "v302"
      },
      {
        "type": "wait",
        "sec": 8.0
      },
      {
        "type": "_comment",
        "_": "── 浄化：自分にお札を貼る ──"
      },
      {
        "type": "horror_glitch",
        "intensity": 5.0,
        "dur": 1.0
      },
      {
        "type": "say",
        "text": "御札、浄化して！！ 私は……私は最高のストリーマーになるんだ！！",
        "voice": "v303"
      },
      {
        "type": "wait",
        "sec": 5.0
      },
      {
        "type": "say",
        "text": "……あ、動ける！ 霧が晴れたみたい。よし、民家を調べて儀式の道具を奪いに行くよ！",
        "voice": "v304"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "廃村感えぐすぎる",
        "user": "幽霊ガチ勢",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "建物が全部朽ちてる…",
        "user": "暗闇ウォッチャー",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "人が住んでたんだよね、ここ",
        "user": "ゆきんこ77",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "say",
        "text": "家が…全部、扉が開けっ放し。誰かが急いで逃げたみたいな",
        "voice": "v302"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "廃村になった理由って何？",
        "user": "配信民99",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "調べた？",
        "user": "深夜探偵",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "調べたけど、記録がほとんど残ってない。1990年代に突然村が無人になったらしい",
        "voice": "v303"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "chat",
        "msg": "人が消えた…",
        "user": "ゆきんこ77",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "それ怖すぎだろｗ",
        "user": "配信民99",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.6
      },
      {
        "type": "say_clear"
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_z",
        "target": 16.0,
        "dur": 7.5,
        "id": "walk1"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "家の扉開いてる…",
        "user": "ゆきんこ77",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "廃村感リアルすぎ",
        "user": "ホラー好き太郎",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "pos_z_await",
        "id": "walk1"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "rot_y",
        "target": 1.57,
        "dur": 0.8
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "…左の家の中。椅子の上に何か座ってる",
        "voice": "v304"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "chat",
        "msg": "人形！？",
        "user": "配信民99",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "映してーー！！",
        "user": "ホラー好き太郎",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "head_x",
        "target": 0.2,
        "dur": 0.5
      },
      {
        "type": "say",
        "text": "…目が、ない。人形の目のところが、空洞になってる",
        "voice": "v305"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "こわっっっ！！",
        "user": "ゆきんこ77",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "なんで目を取るんだ…",
        "user": "幽霊ガチ勢",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "全部の家にある？",
        "user": "深夜探偵",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "head_x",
        "target": 0.0,
        "dur": 0.4
      },
      {
        "type": "rot_y",
        "target": -1.57,
        "dur": 0.8
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "右の家にも。全部に、目のない人形が一体ずつ。村人の数だけ座ってる",
        "voice": "v306"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "全員分の人形？",
        "user": "暗闇ウォッチャー",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "村人の数と同じだったりして",
        "user": "深夜探偵",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "rot_y",
        "target": 0.0,
        "dur": 0.6
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "say_clear"
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_z",
        "target": 8.0,
        "dur": 5.5,
        "id": "walk2"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "chat",
        "msg": "掲示板みたいなの見えるｗ",
        "user": "ホラー好き太郎",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "pos_z_await",
        "id": "walk2"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "rot_y",
        "target": -0.7,
        "dur": 0.6
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "…朽ちた掲示板に、紙が貼ってある。読めるか",
        "voice": "v307"
      },
      {
        "type": "wait",
        "sec": 0.9
      },
      {
        "type": "chat",
        "msg": "読んで読んで！！",
        "user": "ホラー好き太郎",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "…新聞？「霧原村　謎の失踪事件　女系制と奇習　村を出ようとした少女の末路」",
        "voice": "v308"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "chat",
        "msg": "奇習！？",
        "user": "配信民99",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "なに書いてある！？",
        "user": "ゆきんこ77",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "…「この村は女系制であり、外部の男性は『種』として連れてこられた。男性は3歳で眼を摘出される。外の世界を見せないため——逃げられなくするためだ」",
        "voice": "v309"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "え",
        "user": "視聴者A",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "3歳で…",
        "user": "ゆきんこ77",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "眼が空洞の人形はそういうことか",
        "user": "深夜探偵",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "say",
        "text": "…みゆき。首を…見せしめ。だから人形の目が空洞なのか。この村の男たちは目を奪われてた",
        "reading": "…みゆき。くびを…見せしめ。だから人形の目が空洞なのか。この村の男たちは目を奪われてた",
        "voice": "v310"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "chat",
        "msg": "続き読んで",
        "user": "深夜探偵",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "…「1994年10月、少女『みゆき』が村の男と駆け落ちを図り捕縛。見せしめに首を——」…破れて読めない。「その直後、村民は一夜にして全員が」…ここも読めない",
        "reading": "…「1994年10月、少女『みゆき』が村の男と駆け落ちを図り捕縛。見せしめにくびを——」…破れて読めない。「その直後、村民は一夜にして全員が」…ここも読めない",
        "voice": "v311"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "1994年…",
        "user": "視聴者A",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "トイレのスマホと同じ年",
        "user": "深夜探偵",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "繋がってる！！",
        "user": "ホラー好き太郎",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "rot_y",
        "target": 0.0,
        "dur": 0.6
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_z",
        "target": -2.0,
        "dur": 7.0,
        "id": "walk3"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "say",
        "text": "1994年。あのスマホの刻印と同じ年だ。偶然じゃない",
        "voice": "v312"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "chat",
        "msg": "何が起きたの1994年に",
        "user": "ゆきんこ77",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "続きを探して",
        "user": "深夜探偵",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "pos_z_await",
        "id": "walk3"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "rot_y",
        "target": 1.57,
        "dur": 0.8
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "奥の家に行く。一番大きい家だ",
        "voice": "v313"
      },
      {
        "type": "wait",
        "sec": 0.9
      },
      {
        "type": "chat",
        "msg": "ここが中心家族の家かな",
        "user": "暗闇ウォッチャー",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "どうやって入る？",
        "user": "配信民99",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "入れ",
        "user": "K",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say_clear"
      },
      {
        "type": "choice",
        "title": "▼  踏 み 込 む か  ▼",
        "prompt": "村で一番大きな家。扉は開いている。",
        "choices": [
          {
            "text": "正面から堂々と入る",
            "sub": "配信映えはする。だが何がいるかわからない"
          },
          {
            "text": "窓から先に中を覗く",
            "sub": "慎重に。中の様子を確認してからでも遅くない"
          },
          {
            "text": "チャットに聞く——入るべきか",
            "sub": "100人の目は1人の判断に勝る…はず"
          }
        ]
      },
      {
        "type": "say",
        "text": "…入る。ここまで来て引き返す選択肢はない",
        "voice": "v314"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "chat",
        "msg": "入ったぞ！！",
        "user": "ホラー好き太郎",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "入れ",
        "user": "K",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_x",
        "target": -13.0,
        "dur": 7.0,
        "id": "walk_west"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "なんかあるかな",
        "user": "配信民99",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "pos_x_await",
        "id": "walk_west"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "rot_y",
        "target": -1.57,
        "dur": 0.6
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "…押し入れが開いてる。中を見ると",
        "voice": "v315"
      },
      {
        "type": "wait",
        "sec": 1.2
      },
      {
        "type": "chat",
        "msg": "何が入ってる！？",
        "user": "配信民99",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "…スマホが。大量にスマホが詰め込まれてる。全部画面が割れてる",
        "voice": "v316"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "chat",
        "msg": "えっっっ！！",
        "user": "ゆきんこ77",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "何台あるの",
        "user": "視聴者A",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "集めてたの？",
        "user": "幽霊ガチ勢",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.6
      },
      {
        "type": "say",
        "text": "数えられないくらい。全部に「見ている」って通知が残ってる。誰からの通知なんだ",
        "voice": "v317"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "見ている…？",
        "user": "配信民99",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "誰が？",
        "user": "ゆきんこ77",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "見ている",
        "user": "K",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "say",
        "text": "…K？誰だ。今どこで見てる",
        "voice": "v318"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "chat",
        "msg": "Kって誰",
        "user": "配信民99",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "初見さん？",
        "user": "ゆきんこ77",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "見ている",
        "user": "K",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.6
      },
      {
        "type": "chat",
        "msg": "どこを見てるの",
        "user": "深夜探偵",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "見ている",
        "user": "K",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "say",
        "text": "…Kさん、ちょっと怖いんですけど（笑）。ここにいるの？",
        "voice": "v319"
      },
      {
        "type": "wait",
        "sec": 1.2
      },
      {
        "type": "chat",
        "msg": "Kってもしかして…",
        "user": "幽霊ガチ勢",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "スルーしてｗ",
        "user": "配信民99",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "say_clear"
      },
      {
        "type": "rot_y",
        "target": -1.57,
        "dur": 0.6
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_x",
        "target": 0.0,
        "dur": 7.0,
        "id": "return_road"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "say",
        "text": "倉庫に向かう。VHSテープを探すのが目的だから。そこに真実がある",
        "voice": "v320"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "そうだった！！VHS！！",
        "user": "ホラー好き太郎",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "頑張れ！！",
        "user": "ゆきんこ77",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "見ている",
        "user": "K",
        "utype": "viewer"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "pos_x_await",
        "id": "return_road"
      },
      {
        "type": "rot_y",
        "target": 0.0,
        "dur": 0.5
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "say_clear"
      }
    ]
  },
  "ch02_yashiki": {
    "chapter": "ch02_yashiki",
    "_note": "CP2 村長の屋敷 — 安産祈願の札・日記・女系村の秘密・鏡の恐怖",
    "events": [
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション1：玄関到着・屋敷へ入る】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "sfx",
        "sound": "ambient_wind"
      },
      {
        "type": "set_viewers",
        "count": 5000
      },
      {
        "type": "say",
        "text": "……大きい家。ここが村長の屋敷か",
        "voice": "v241"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "でかっ！！",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "さっきのトイレの後でこれ…",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "トイレのあれまだ心臓バクバクなんだが",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "say",
        "text": "玄関の引き戸が……半分開いてる。入れってこと？",
        "voice": "v242"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "sfx",
        "sound": "door_creak"
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_z",
        "target": 9.7,
        "dur": 3.0,
        "id": "enter_genkan"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "chat",
        "msg": "入るんかいｗ",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "不法侵入定期",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "pos_z_await",
        "id": "enter_genkan"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "_comment",
        "_": "── 玄関内部・安産祈願の札を発見 ──"
      },
      {
        "type": "say",
        "text": "……玄関の上がり框に靴が並んでる。女物ばっかり",
        "voice": "v243"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "rot_y",
        "target": 1.57,
        "dur": 0.8
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "壁にお札がびっしり。全部同じ文字……「安産祈願」",
        "voice": "v244"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "安産祈願？",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "数がおかしいだろ",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "何枚あるの…",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "100枚以上あるよこれ。全部手書き。同じ筆跡で……執念みたいなものを感じる",
        "voice": "v245"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "rot_y",
        "target": -1.57,
        "dur": 0.8
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "反対側の壁にも。天井にも。隙間なくお札で埋め尽くされてる",
        "voice": "v246"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "chat",
        "msg": "やばすぎる…",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "村長の家でこれってことは村ぐるみ？",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "rot_y",
        "target": 0.0,
        "dur": 0.6
      },
      {
        "type": "say_clear"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション2：土間から広間へ】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_z",
        "target": 4.7,
        "dur": 6.0,
        "id": "walk_doma"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "say",
        "text": "土間を進む。板の間がギシギシいってる",
        "voice": "v247"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "sfx",
        "sound": "wooden_floor"
      },
      {
        "type": "chat",
        "msg": "音やばｗ",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "踏み抜かない？大丈夫？",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "pos_z_await",
        "id": "walk_doma"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "say",
        "text": "広間に出た。囲炉裏がある。ここでも壁一面に安産祈願の札",
        "voice": "v248"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "head_x",
        "target": -0.3,
        "dur": 0.8
      },
      {
        "type": "say",
        "text": "……囲炉裏の灰の中に、何か焦げた紙が。日記の切れ端？",
        "voice": "v249"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "chat",
        "msg": "燃やそうとしたのか！",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "証拠隠滅…",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "head_x",
        "target": 0.0,
        "dur": 0.5
      },
      {
        "type": "say",
        "text": "読めない。焦げすぎてる。もっと奥を探さないと",
        "voice": "v250"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "奥に行こう！",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "奥から音しない？",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "sfx",
        "sound": "wooden_floor"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "say",
        "text": "……今の音。私じゃない",
        "voice": "v251"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "えっ",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "誰かいる！？",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "ライト！！",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "say",
        "text": "……気のせい、かな。古い家だし、木が軋むだけだよね",
        "voice": "v252"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "say_clear"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション3：視聴者投票 — 3択】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "set_viewers",
        "count": 5400
      },
      {
        "type": "say",
        "text": "屋敷の奥で物音がした。どこから来たんだろう",
        "voice": "v253"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "右の部屋と左の部屋あるよ",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "どこ行く！？",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "みんなに聞くね。どこを調べる？",
        "voice": "v254"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "choice",
        "title": "▼  何 を 調 べ る  ▼",
        "prompt": "屋敷の奥で物音がする。どこを調べる？",
        "choices": [
          {
            "text": "仏間の仏壇を調べる",
            "sub": "線香の匂いがする...誰かが最近供えた？"
          },
          {
            "text": "奥座敷の床の間を調べる",
            "sub": "掛け軸の裏に何か貼ってある"
          },
          {
            "text": "台所のかまどの中を覗く",
            "sub": "灰の中に何か光ってない？これアイスの棒じゃないよね"
          }
        ],
        "targets": [
          "route_butsudan",
          "route_okuzashiki",
          "route_kitchen"
        ]
      },
      {
        "type": "_comment",
        "_": "── 選択肢A：仏間の仏壇 ──"
      },
      {
        "type": "label",
        "name": "route_butsudan"
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "rot_y",
        "target": 1.57,
        "dur": 0.6
      },
      {
        "type": "pos_x",
        "target": 6.5,
        "dur": 4.0,
        "id": "walk_east"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "say",
        "text": "仏間に向かう。……線香の匂いがする。最近誰かが供えた？",
        "voice": "v255"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "pos_x_await",
        "id": "walk_east"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "rot_y",
        "target": 0.0,
        "dur": 0.6
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "線香！？廃村なのに！？",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "誰かいるじゃん…",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "仏壇の引き出し。中に……古い日記帳。表紙に「村長 霧原ハツ」と書いてある",
        "voice": "v256"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "sfx",
        "sound": "door_creak"
      },
      {
        "type": "chat",
        "msg": "日記！！やばいやつ！！",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "位牌が並んでる。全部女の名前。男の名前は……一つもない",
        "voice": "v257"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "chat",
        "msg": "男の位牌がない…",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "goto",
        "label": "converge_diary"
      },
      {
        "type": "_comment",
        "_": "── 選択肢B：奥座敷の床の間 ──"
      },
      {
        "type": "label",
        "name": "route_okuzashiki"
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_z",
        "target": -2.0,
        "dur": 4.0,
        "id": "walk_north"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "say",
        "text": "奥座敷に向かう。床の間に掛け軸が見える",
        "voice": "v258"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "pos_z_await",
        "id": "walk_north"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "掛け軸に「母系万代」と書かれてる。裏に……何か紙が貼ってある",
        "voice": "v259"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "母系万代！？",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "裏に何貼ってるの！？",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "掛け軸を剥がすと……日記帳が隠されてた。表紙に「村長 霧原ハツ」",
        "voice": "v260"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "隠してたのか！",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "掛け軸の裏に何枚も写真が。全部女性。男性は一人も写っていない",
        "voice": "v261"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "chat",
        "msg": "女性だけの集合写真…",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "goto",
        "label": "converge_diary"
      },
      {
        "type": "_comment",
        "_": "── 選択肢C：台所のかまど ──"
      },
      {
        "type": "label",
        "name": "route_kitchen"
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "rot_y",
        "target": -1.57,
        "dur": 0.6
      },
      {
        "type": "pos_x",
        "target": -6.5,
        "dur": 4.0,
        "id": "walk_west"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "say",
        "text": "台所に向かう。かまどがある。灰の中に何か光ってる",
        "voice": "v262"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "pos_x_await",
        "id": "walk_west"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "rot_y",
        "target": 0.0,
        "dur": 0.6
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "head_x",
        "target": -0.3,
        "dur": 0.5
      },
      {
        "type": "say",
        "text": "灰をかき分けると……金属の留め具。日記帳の留め具だ",
        "voice": "v263"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "燃やしきれなかったのか！",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "これアイスの棒じゃないよねって言ったけどマジでやばいやつだったｗ",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "半分焦げてるけど読める。表紙に「村長 霧原ハツ」",
        "voice": "v264"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "head_x",
        "target": 0.0,
        "dur": 0.4
      },
      {
        "type": "chat",
        "msg": "かまどで燃やそうとしたけど燃えきらなかった…",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "say",
        "text": "調理器具が全部包丁と鎌。鍋が一つもない。この台所……料理してた場所じゃないのかも",
        "voice": "v265"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "こわ",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "goto",
        "label": "converge_diary"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション4：合流 — 日記の内容（女系村の秘密）】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "label",
        "name": "converge_diary"
      },
      {
        "type": "say_clear"
      },
      {
        "type": "set_viewers",
        "count": 5800
      },
      {
        "type": "say",
        "text": "日記を開く。最初のページ……昭和六十三年、四月",
        "voice": "v266"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "昭和63年！",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "1988年か",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "「本村は代々、女系の血統を守りてきた。男は外より連れ来るもの。種を頂き、役目を終えた者は山に還す」",
        "voice": "v267"
      },
      {
        "type": "wait",
        "sec": 3.0
      },
      {
        "type": "chat",
        "msg": "は？",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "種……？",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "山に還すって",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "殺してるってこと？",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "say",
        "text": "「男を『種』と呼ぶ。子を成したのち、山の祠にて供養する。これが掟である」",
        "voice": "v268"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "供養って…消してるんだよ",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "やばすぎだろこの村",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "……ページを捲る。何年分もの記録。「種の搬入」「供養完了」って、帳簿みたいに淡々と書いてある",
        "voice": "v269"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "帳簿って…人間の話だよね",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "say",
        "text": "「安産祈願」の札は女児が生まれるように祈るもの。男児が生まれた場合は……「間引く」",
        "voice": "v270"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "間引く……",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "だから安産祈願の札があんなに…",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "女の子が生まれますようにって意味じゃん",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "say",
        "text": "あの大量のお札は……女の子が生まれるように祈ってたんじゃない。男の子が生まれないように、呪ってたんだ",
        "voice": "v271"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "呪い…",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say_clear"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション5：みゆきの記述 — 悲劇の真相】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "set_viewers",
        "count": 6200
      },
      {
        "type": "say",
        "text": "……日記の後半。筆跡が乱れてる。平成六年の記述",
        "voice": "v272"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "平成6年=1994年だ",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "村が消えた年！",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "「九月十二日。みゆきが掟を破った。外から来た種の男と情を交わし、共に村を出ようとした」",
        "voice": "v273"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "みゆき…",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "恋をしちゃったのか",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "「みゆき、十七歳。愚かにも外の男に心を許した。掟を破りし者に慈悲はない」",
        "voice": "v274"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "17歳…私たちと同い年くらいだよ",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "慈悲はないって何するつもり",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "say",
        "text": "「十月一日。村の女衆の前にてみゆきの首を刎ねた。見せしめ也。鎌は祠に奉納す」",
        "reading": "「十月一日。村の女衆の前にてみゆきのくびを刎ねた。見せしめ也。鎌は祠に奉納す」",
        "voice": "v275"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "sfx",
        "sound": "monster_growl",
        "vol": -18
      },
      {
        "type": "chat",
        "msg": "首を",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "鎌で…",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "17歳の女の子の首を鎌で刎ねた？",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "トイレに出てきた首なしの女…",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "say",
        "text": "……あの子だ。トイレで会った首のない女の子。みゆきだったんだ",
        "reading": "……あの子だ。トイレで会ったくびのない女の子。みゆきだったんだ",
        "voice": "v276"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "繋がった…",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "superchat",
        "name": "ガクブル太郎",
        "msg": "しゅっちちゃん早く出て！！",
        "amount": 500
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "say",
        "text": "「十月三日。みゆきの首を刎ねた夜より、村に異変あり。女衆が次々と鏡の前で狂い始めた」",
        "reading": "「十月三日。みゆきのくびを刎ねた夜より、村に異変あり。女衆が次々と鏡の前で狂い始めた」",
        "voice": "v277"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "鏡…？",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "みゆきの呪い！？",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "「鏡に映る己の姿が、首のない老婆に変わると言う。手には血の鎌。みゆきを殺した鎌だ」",
        "reading": "「鏡に映る己の姿が、くびのない老婆に変わると言う。手には血の鎌。みゆきを殺した鎌だ」",
        "voice": "v278"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "首なしの老婆…",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "自分が首なしになるの！？",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "「十月七日。記す。我が村は終わった。鏡の呪いが止まらぬ。これが最後の記述と——」途切れてる",
        "voice": "v279"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "ここで日記が終わってる…",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "村長も鏡の呪いにかかったんだ",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "say_clear"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション6：鏡の部屋へ移動 — ホラークライマックス】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "set_viewers",
        "count": 6800
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "rot_y",
        "target": 1.57,
        "dur": 0.6
      },
      {
        "type": "pos_x",
        "target": 6.5,
        "dur": 4.0,
        "id": "walk_to_mirror_x"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "say",
        "text": "鏡の呪い……この屋敷のどこかに鏡があるはず",
        "voice": "v280"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "chat",
        "msg": "見に行くの！？",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "行かないで",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "pos_x_await",
        "id": "walk_to_mirror_x"
      },
      {
        "type": "rot_y",
        "target": 0.0,
        "dur": 0.6
      },
      {
        "type": "pos_z",
        "target": 1.0,
        "dur": 3.0,
        "id": "walk_to_mirror_z"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "say",
        "text": "東の座敷。奥に大きな姿見がある",
        "voice": "v281"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "鏡だ！！",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "pos_z_await",
        "id": "walk_to_mirror_z"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "……鏡に近づく。私の姿が映ってる。普通に映ってる",
        "voice": "v282"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "普通じゃん",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "後ろ",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "Kまた出た",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "say",
        "text": "後ろ？鏡の中の、私の後ろに——",
        "voice": "v283"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "_comment",
        "_": "── 鏡の恐怖演出 ──"
      },
      {
        "type": "sfx",
        "sound": "monster_growl",
        "vol": -8
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "say",
        "text": "——ッ！！鏡の中！！後ろに！！首のない……老婆が！！鎌を持って！！",
        "reading": "——ッ！！鏡の中！！後ろに！！くびのない……老婆が！！鎌を持って！！",
        "voice": "v284"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "ぎゃああああ",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "首ない！！！！",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "逃げろ！！！",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "鎌持ってるの血ついてない！？",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "一人じゃない……鏡の中に何人もいる！！全員首がない！！全員鎌を持ってる！！",
        "reading": "一人じゃない……鏡の中に何人もいる！！全員くびがない！！全員鎌を持ってる！！",
        "voice": "v285"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "sfx",
        "sound": "monster_growl",
        "vol": -6
      },
      {
        "type": "chat",
        "msg": "何人もいるって",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "村の女衆だ…日記に書いてあった",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "みゆきを殺した連中が呪われて首なしになったのか",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "say",
        "text": "振り返る——何もいない。でも鏡を見ると——まだいる。こっちを向いてる",
        "voice": "v286"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "rot_y",
        "target": 3.14,
        "dur": 0.4
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "rot_y",
        "target": 0.0,
        "dur": 0.4
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "近づいてくる！！鏡の中でだんだん近づいてくる！！",
        "voice": "v287"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "sfx",
        "sound": "monster_growl",
        "vol": -3
      },
      {
        "type": "chat",
        "msg": "逃げてえええ！！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "鏡見るな！！",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "superchat",
        "name": "幽霊ガチ勢",
        "msg": "鏡から離れろ！！今すぐ！！",
        "amount": 1000
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say_clear"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション7：呪いのコメント洪水】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "set_viewers",
        "count": 7200
      },
      {
        "type": "say",
        "text": "——ハァッ……ハァッ……鏡から目を逸らした。もう見ない",
        "voice": "v288"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "掟を破ったな",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "えっ",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "生け贄だ",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "Kが何か言ってる！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "ここに来てはならなかった",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "見てしまった",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "Kって何者なの",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "お前も種と同じだ",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "鎌を研いでいる",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "やめてくれ…",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "これBOTだよね？BOTだと言ってくれ",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "K……あなたは誰。この村の人間？",
        "voice": "v289"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "みゆきは逃げられなかった",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "お前も逃げられない",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "……っ。チャット欄が。Kの書き込みだらけに——",
        "voice": "v290"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "BANしろ！！",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "通報した",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "見ている",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.7
      },
      {
        "type": "say_clear"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション8：倉への手がかり発見・撤退】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "set_viewers",
        "count": 7800
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "rot_y",
        "target": 3.14,
        "dur": 0.5
      },
      {
        "type": "pos_z",
        "target": 4.0,
        "dur": 3.0,
        "id": "retreat1"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "say",
        "text": "逃げる。この部屋から逃げる",
        "voice": "v291"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "pos_z_await",
        "id": "retreat1"
      },
      {
        "type": "rot_y",
        "target": -1.57,
        "dur": 0.5
      },
      {
        "type": "pos_x",
        "target": 0.0,
        "dur": 3.5,
        "id": "retreat2"
      },
      {
        "type": "wait",
        "sec": 1.0
      },
      {
        "type": "say",
        "text": "……待って。広間の囲炉裏の横に、もう一枚紙が落ちてる",
        "voice": "v292"
      },
      {
        "type": "wait",
        "sec": 1.8
      },
      {
        "type": "pos_x_await",
        "id": "retreat2"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "head_x",
        "target": -0.3,
        "dur": 0.5
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "メモだ。「倉の中に記録が残っている。VHSテープ。全ての真実が映っている」",
        "voice": "v293"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "VHS！！",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "倉に行かなきゃ",
        "user": "深夜組"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "次のチャプターの伏線だ！！",
        "user": "幽霊ガチ勢",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "head_x",
        "target": 0.0,
        "dur": 0.4
      },
      {
        "type": "say",
        "text": "VHSテープ……あの倉庫にあるってことか。行くしかない",
        "voice": "v294"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "頑張れしゅっち！！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "superchat",
        "name": "ホラー好き太郎",
        "msg": "最高の配信！！倉庫編も楽しみ！",
        "amount": 2000
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "say_clear"
      },
      {
        "type": "_comment",
        "_": "── 出口へ向かう ──"
      },
      {
        "type": "set_viewers",
        "count": 8000
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "rot_y",
        "target": 3.14,
        "dur": 0.5
      },
      {
        "type": "pos_z",
        "target": 10.0,
        "dur": 6.0,
        "id": "walk_exit"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "say",
        "text": "この屋敷から出る。倉庫に向かう",
        "voice": "v295"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "chat",
        "msg": "走って！！",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "鏡見るなよ！絶対見るなよ！",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "sfx",
        "sound": "monster_growl",
        "vol": -20
      },
      {
        "type": "chat",
        "msg": "今なんか聞こえなかった？",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "待っている",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "pos_z_await",
        "id": "walk_exit"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say",
        "text": "……みゆき。あなたの無念は、あのVHSで証明してみせる",
        "voice": "v296"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "しゅっち……",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "同接8000人突破！！",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "say_clear"
      },
      {
        "type": "fade_black",
        "dur": 1.5
      },
      {
        "type": "wait",
        "sec": 1.0
      }
    ]
  },
  "ch03_minka": {
    "chapter": "ch03_minka",
    "_note": "CP3 民家探索 — 新しい道具（頭、鎌、御札）の発見と恐怖演出",
    "events": [
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【シーン1：民家導入 — 目的の提示】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "say",
        "text": "ここが村の奥の民家か……。神社の封印を解除する、あの不気味な道具を探さないと。",
        "voice": "v301"
      },
      {
        "type": "wait",
        "sec": 4.5
      },
      {
        "type": "say",
        "text": "『木彫りの頭』と『錆びた鎌』……それに『写し鏡の御札』。おばあちゃん、なんでこんな物を持っていけなんて言ったんだろ。",
        "voice": "v302"
      },
      {
        "type": "wait",
        "sec": 6.8
      },
      {
        "type": "chat",
        "msg": "アイテム名からしてヤバいんだが",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "人形師の家って噂あるよねここ",
        "user": "幽霊ガチ勢"
      },
      {
        "type": "wait",
        "sec": 1.2
      },
      {
        "type": "say",
        "text": "……なんか、さっきから視線を感じる。案山子に見つからないように、慎重に奥まで調べよう。",
        "voice": "v303"
      },
      {
        "type": "wait",
        "sec": 5.5
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【アイテム発見イベント：道具A・眼球の頭】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "event",
        "id": "collect_head",
        "events": [
          {
            "type": "vhs_glitch",
            "intensity": 0.2,
            "dur": 0.3
          },
          {
            "type": "say",
            "text": "うわっ……！ これが木彫りの頭……？ 表面が焼けてるみたいで……ひっ、眼球だけが異常に生々しい……。",
            "voice": "v304"
          },
          {
            "type": "wait",
            "sec": 7.5
          },
          {
            "type": "chat",
            "msg": "うわっ、こっち見た！？",
            "user": "ビビり散らし隊"
          },
          {
            "type": "wait",
            "sec": 0.3
          },
          {
            "type": "chat",
            "msg": "カメラ追ってきてないかこれ",
            "user": "ゆきんこ77",
            "utype": "moderator"
          },
          {
            "type": "wait",
            "sec": 0.5
          },
          {
            "type": "say",
            "text": "……なんか、ずっと見られてる気がする。スマホを動かしても、視線が離れないの。最悪……。",
            "voice": "v305"
          }
        ]
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【アイテム発見イベント：道具B・錆びた鎌】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "event",
        "id": "collect_sickle",
        "events": [
          {
            "type": "sfx",
            "sound": "impact_heavy"
          },
          {
            "type": "horror_glitch",
            "intensity": 1.5,
            "count": 2
          },
          {
            "type": "say",
            "text": "重い……。この錆びた鎌、誰かの強い恨みがこもってる気がする。持ってるだけで頭が痛くなってくる……。",
            "voice": "v306"
          },
          {
            "type": "wait",
            "sec": 7.2
          },
          {
            "type": "chat",
            "msg": "ノイズひどくなってない？",
            "user": "配信民99",
            "utype": "member"
          },
          {
            "type": "wait",
            "sec": 0.4
          },
          {
            "type": "chat",
            "msg": "Encoding Error出てるぞ！",
            "user": "技術班A"
          },
          {
            "type": "wait",
            "sec": 0.6
          },
          {
            "type": "say",
            "text": "……ゲートのあの髪の毛みたいな紐、これで切れるかな。早く終わらせて手放したい……。",
            "voice": "v307"
          }
        ]
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【アイテム発見イベント：道具C・写し鏡の御札】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "event",
        "id": "collect_mirror_charm",
        "events": [
          {
            "type": "sfx",
            "sound": "magic_scary"
          },
          {
            "type": "vhs_glitch",
            "intensity": 0.4,
            "dur": 1.0
          },
          {
            "type": "say",
            "text": "仏壇の中に……写し鏡の御札？ なにこれ、鏡みたいに反射し……えっ、待って。画面の中……あたしの顔が……。",
            "voice": "v308"
          },
          {
            "type": "wait",
            "sec": 8.5
          },
          {
            "type": "chat",
            "msg": "え、しゅっち！？",
            "user": "視聴者B"
          },
          {
            "type": "wait",
            "sec": 0.3
          },
          {
            "type": "chat",
            "msg": "今一瞬、顔が案山子に……",
            "user": "深夜のツッコミ担当"
          },
          {
            "type": "wait",
            "sec": 0.5
          },
          {
            "type": "say",
            "text": "……ひっ！ い、今、案山子の顔になってなかった！？ ねえ、みんなも見えたよね！？ 怖い、怖いんだけど！！",
            "voice": "v309"
          }
        ]
      }
    ]
  },
  "ch04_jinja": {
    "chapter": "ch04_jinja",
    "_note": "CP4 神社 ─ 10万人の視線 ─ 白木の箱・みゆきの生首・藁コメフラッド・最後のお札発見",
    "events": [
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション1：神社本殿に入る】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "sfx",
        "sound": "ambient_wind"
      },
      {
        "type": "set_viewers",
        "count": 65000
      },
      {
        "type": "flashlight_on"
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_z",
        "target": 22.0,
        "dur": 5.0,
        "id": "enter_shrine"
      },
      {
        "type": "say",
        "text": "儀式の道具を祭壇に供えたら……門が開いた。本殿の中に入るよ",
        "voice": "v401"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "sfx",
        "file": "res://assets/audio/sfx/door/creak1.ogg",
        "vol": -3.0
      },
      {
        "type": "chat",
        "msg": "ついに神社の中…",
        "user": "廃墟マニア",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "絶対やばいやつ",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "入らない方がいいって！！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "fog_change",
        "density": 0.06,
        "dur": 3.0,
        "color": [
          0.06,
          0.02,
          0.02
        ]
      },
      {
        "type": "say",
        "text": "空気が変わった……冷たい。嫌な予感がする",
        "voice": "v402"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "pos_z_await",
        "id": "enter_shrine"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション2：祭壇・白木の箱を発見】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "say",
        "text": "祭壇がある……真ん中に白い箱が置いてある",
        "voice": "v403"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "pos_z_await",
        "id": "approach_altar"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "say",
        "text": "祭壇の上に白木の箱がある。これ……開けてみるね",
        "voice": "v403_alt"
      },
      {
        "type": "wait",
        "sec": 3.5
      },
      {
        "type": "sfx",
        "sound": "box_open"
      },
      {
        "type": "camera_shake",
        "intensity": 0.05,
        "dur": 1.0
      },
      {
        "type": "say",
        "text": "これ……みゆきちゃんの首。……生きてる？ 生きてカメラを見てる。……あ。同接、10万、いった。……いったよ！！ 見て、私が、私が世界で一番の……！",
        "voice": "v404"
      },
      {
        "type": "wait",
        "sec": 12.0
      },
      {
        "type": "chat_horror_mode",
        "dur": 20
      },
      {
        "type": "set_viewers",
        "count": 100000
      },
      {
        "type": "chat",
        "msg": "藁",
        "user": "視聴者A"
      },
      {
        "type": "chat",
        "msg": "藁藁藁藁藁",
        "user": "配信民99"
      },
      {
        "type": "chat",
        "msg": "首ヲ置ケ",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "chat",
        "msg": "案山子ニ成レ",
        "user": "K",
        "utype": "horror"
      },
      {
        "type": "say",
        "text": "何これ、コメントが全部『藁』！？ 身体がまた止まりそう……。でも、最後のお札が見つかった。これさえあれば……これさえあれば勝てる！",
        "voice": "v405"
      },
      {
        "type": "wait",
        "sec": 8.5
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "絶対開けるだろ",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "superchat",
        "name": "恐怖のスパチャ",
        "msg": "開けたら1万円",
        "amount": 10000
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "pos_z_await",
        "id": "approach_altar"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "say",
        "text": "……開けるよ",
        "voice": "v404"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "motion",
        "name": "look_down_up",
        "dur": 1.5
      },
      {
        "type": "head_x",
        "target": 0.3,
        "dur": 0.8
      },
      {
        "type": "sfx",
        "file": "res://assets/audio/sfx/door/creak3.ogg",
        "vol": -2.0
      },
      {
        "type": "sleep",
        "sec": 1.5
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション3：みゆきの生首・衝撃】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "horror_flash",
        "dur": 0.2
      },
      {
        "type": "sfx",
        "file": "res://assets/audio/sfx/metal/impactMetal_heavy_000.ogg",
        "vol": 0.0
      },
      {
        "type": "camera_shake",
        "intensity": 0.08,
        "dur": 1.0
      },
      {
        "type": "say",
        "text": "これ……みゆきちゃんの首",
        "reading": "これ……みゆきちゃんのくび",
        "voice": "v405"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "vhs_glitch",
        "intensity": 0.5,
        "dur": 0.8
      },
      {
        "type": "chat",
        "msg": "！！！！！",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "うわああああ",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "首！？首！？",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "通報した方がいい",
        "user": "常識人",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "say",
        "text": "……生きてる？ 生きてカメラを見てる",
        "voice": "v406"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "fisheye",
        "distortion": 0.3,
        "breath": 0.05,
        "dur": 1.5
      },
      {
        "type": "horror_tint"
      },
      {
        "type": "say",
        "text": "目が……こっちを見てる。瞬きしてる！",
        "voice": "v407"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "chat",
        "msg": "まばたきした！！",
        "user": "夜更かし太郎"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "逃げろ！！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション4：同接10万突破・承認欲求の頂点】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "set_viewers",
        "count": 78000
      },
      {
        "type": "say",
        "text": "……あ。同接が……上がってる",
        "reading": "……あ。どうせつが……上がってる",
        "voice": "v408"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "set_viewers",
        "count": 85000
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "set_viewers",
        "count": 92000
      },
      {
        "type": "chat",
        "msg": "同接すごいことになってる",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "set_viewers",
        "count": 97000
      },
      {
        "type": "superchat",
        "name": "赤スパの人",
        "msg": "これガチ？",
        "amount": 50000
      },
      {
        "type": "wait",
        "sec": 0.8
      },
      {
        "type": "set_viewers",
        "count": 100000
      },
      {
        "type": "scare_flash",
        "color": "white"
      },
      {
        "type": "say",
        "text": "10万……いった。……いったよ！！",
        "voice": "v409"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat",
        "msg": "10万人突破！！！",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "say",
        "text": "見て、私が、私が世界で一番の……！",
        "voice": "v410"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション5：コメント「藁」フラッド・呪い暴走】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "chat_flood",
        "msg": "藁",
        "count": 8,
        "interval": 0.15,
        "color": "red"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "vhs_glitch",
        "intensity": 0.7,
        "dur": 2.0
      },
      {
        "type": "horror_red",
        "dur": 15.0
      },
      {
        "type": "say",
        "text": "何これ、コメントが全部『藁』！？",
        "voice": "v411"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "chat_flood",
        "msg": "藁藁藁藁藁",
        "count": 10,
        "interval": 0.1,
        "color": "red"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "首ヲ置ケ",
        "user": "???",
        "utype": "owner"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "案山子ニ成レ",
        "user": "???",
        "utype": "owner"
      },
      {
        "type": "wait",
        "sec": 0.6
      },
      {
        "type": "chat_flood",
        "msg": "藁",
        "count": 12,
        "interval": 0.08,
        "color": "red"
      },
      {
        "type": "set_fps",
        "fps": 20
      },
      {
        "type": "camera_shake",
        "intensity": 0.05,
        "dur": 3.0
      },
      {
        "type": "say",
        "text": "身体がまた止まりそう……ゲージが……減らない！",
        "voice": "v412"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "desaturate",
        "amount": 0.4,
        "dur": 1.0
      },
      {
        "type": "set_fps",
        "fps": 12
      },
      {
        "type": "chat_flood",
        "msg": "藁藁藁",
        "count": 6,
        "interval": 0.12,
        "color": "red"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション6：最後のお札を発見】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "say",
        "text": "でも、最後のお札が……あった！ 祭壇の裏に！",
        "voice": "v413"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "sfx",
        "file": "res://assets/audio/sfx/bell/impactBell_heavy_001.ogg",
        "vol": -4.0
      },
      {
        "type": "chat",
        "msg": "お札！！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.4
      },
      {
        "type": "chat",
        "msg": "最後の1枚…！",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.6
      },
      {
        "type": "say",
        "text": "これさえあれば……これさえあれば勝てる！",
        "voice": "v414"
      },
      {
        "type": "wait",
        "sec": 2.0
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "_comment",
        "_": "【セクション7：案山子出現・脱出開始】"
      },
      {
        "type": "_comment",
        "_": "════════════════════════════════════════════"
      },
      {
        "type": "sfx",
        "file": "res://assets/audio/sfx/metal/impactMetal_heavy_002.ogg",
        "vol": -1.0
      },
      {
        "type": "horror_glitch",
        "intensity": 10.0,
        "count": 4
      },
      {
        "type": "camera_shake",
        "intensity": 0.1,
        "dur": 1.5
      },
      {
        "type": "say",
        "text": "！？ 案山子が……動いてる！ バス停への道を塞いでる！！",
        "voice": "v415"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "flashlight_flicker"
      },
      {
        "type": "chat",
        "msg": "うわああ動いたああ",
        "user": "ガクブル太郎"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "首なし案山子！！",
        "user": "視聴者A"
      },
      {
        "type": "wait",
        "sec": 0.3
      },
      {
        "type": "chat",
        "msg": "ワープしてるぞ！？",
        "user": "配信民99",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat_flood",
        "msg": "藁",
        "count": 5,
        "interval": 0.2,
        "color": "red"
      },
      {
        "type": "say",
        "text": "逃げる！！ バス停まで走れ！！",
        "voice": "v416"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "walk_set",
        "on": true
      },
      {
        "type": "rot_y",
        "target": 3.14,
        "dur": 0.8
      },
      {
        "type": "pos_z",
        "target": 30.0,
        "dur": 5.0,
        "id": "escape_shrine"
      },
      {
        "type": "set_fps",
        "fps": 8
      },
      {
        "type": "say",
        "text": "身体がカクカクする……でも止まったら終わりだ！",
        "voice": "v417"
      },
      {
        "type": "wait",
        "sec": 2.5
      },
      {
        "type": "sfx",
        "file": "res://assets/audio/sfx/metal/impactMetal_heavy_004.ogg",
        "vol": -2.0
      },
      {
        "type": "vhs_glitch",
        "intensity": 0.6,
        "dur": 1.0
      },
      {
        "type": "chat",
        "msg": "走れ走れ走れ！！",
        "user": "ゆきんこ77",
        "utype": "moderator"
      },
      {
        "type": "wait",
        "sec": 0.5
      },
      {
        "type": "chat",
        "msg": "案山子追ってきてる！！",
        "user": "ホラー好き太郎",
        "utype": "member"
      },
      {
        "type": "wait",
        "sec": 1.5
      },
      {
        "type": "pos_z_await",
        "id": "escape_shrine"
      },
      {
        "type": "walk_set",
        "on": false
      },
      {
        "type": "horror_red_clear"
      },
      {
        "type": "fisheye_off",
        "dur": 0.5
      },
      {
        "type": "horror_tint_clear"
      },
      {
        "type": "fade_black",
        "dur": 0.8
      },
      {
        "type": "set_fps",
        "fps": 0
      },
      {
        "type": "desaturate",
        "amount": 0.0,
        "dur": 0.3
      },
      {
        "type": "say_clear"
      },
      {
        "type": "set_viewers",
        "count": 105000
      },
      {
        "type": "sleep",
        "sec": 1.0
      },
      {
        "type": "fade_clear",
        "dur": 0.8
      }
    ]
  },
  "opening": {
    "chapter": "opening",
    "profile": {
      "speed": 0.018,
      "wait": 2.5,
      "fade_in": 0.7,
      "fade_out": 0.5,
      "lines": [
        {
          "text": "しゅっち ch",
          "style": "name"
        },
        {
          "text": "@shucchi_horror",
          "style": "handle"
        },
        {
          "text": "JK配信者 / ホラー凸 / 心霊スポット巡り",
          "style": "bio"
        },
        {
          "text": "「配信で一発当てて、人生変えてやる」",
          "style": "bio"
        },
        {
          "text": "▶ 動画 7本　　👥 347人登録",
          "style": "stats"
        },
        {
          "text": "深夜の廃病院、制服で行ってみた（再生数 210）",
          "style": "video"
        },
        {
          "text": "心霊スポット行ったけど何も起きなかった（再生数 83）",
          "style": "video"
        },
        {
          "text": "廃トンネルに潜入したら…（再生数 41）",
          "style": "video"
        },
        {
          "text": "収益化まであと 653人……",
          "style": "warning"
        }
      ]
    },
    "dm": {
      "speed": 0.022,
      "wait": 0.6,
      "glitch_count": 5,
      "fade_in": 0.5,
      "fade_out": 0.5,
      "lines": [
        {
          "text": "⚠ アカウント削除済み",
          "style": "alert"
        },
        {
          "text": "はじめまして。しゅっちさんですよね。",
          "style": "normal"
        },
        {
          "text": "今夜、霧原村に行ってみてください。",
          "style": "bold"
        },
        {
          "text": "1994年に「事件」があった廃村です。",
          "style": "normal"
        },
        {
          "text": "そこに、証拠のVHSがあります。配信すれば…間違いなく、バズります。",
          "style": "normal"
        },
        {
          "text": "場所は県道沿い、霧の多い山道を進んだ先。",
          "style": "normal"
        },
        {
          "text": "必ず、深夜0時に入ってください。",
          "style": "bold"
        },
        {
          "text": "…あなたのこと、見ています。",
          "style": "creepy"
        }
      ]
    },
    "scary_flash": {
      "text": "見 て い る"
    },
    "monologue": {
      "speed": 0.036,
      "wait": 2.0,
      "fade_in": 0.5,
      "fade_out": 0.5,
      "lines": [
        {
          "text": "（ 自室、深夜 ── スマホの画面を見つめて ）",
          "style": "stage_direction"
        },
        {
          "text": "「…怪しいDM。アカウントも消えてるし」",
          "style": "dialogue_strong"
        },
        {
          "text": "「でも……霧原村か」",
          "style": "dialogue"
        },
        {
          "text": "「有名な心霊スポットだし、本物だったらマジでバズるかも」",
          "style": "dialogue"
        },
        {
          "text": "「再生数ぜんっぜん伸びない。登録者347人」",
          "style": "dialogue_dim"
        },
        {
          "text": "「収益化なんて夢のまた夢」",
          "style": "dialogue_dim"
        },
        {
          "text": "「来月の携帯代も怪しいのに」",
          "style": "dialogue_faint"
        },
        {
          "text": "「お母さんにはこれ以上頼れない……」",
          "style": "dialogue_faint"
        },
        {
          "text": "「あたしには配信しかないんだ」",
          "style": "dialogue"
        },
        {
          "text": "「誰かが見てくれてる限り、あたしは大丈夫」",
          "style": "dialogue_faint"
        },
        {
          "text": "（ ── 深夜0時。霧原村行き最終バスに乗り込んだ ）",
          "style": "stage_direction"
        },
        {
          "text": "「── 行くしかない」",
          "style": "final"
        }
      ]
    },
    "caption": {
      "char_speed": 0.07,
      "line_wait": 0.3,
      "display_wait": 2.5,
      "fade_in": 1.0,
      "fade_out": 0.8,
      "lines": [
        "霧 原 村",
        "",
        "深 夜   0 : 0 0"
      ]
    },
    "timing": {
      "initial_wait": 0.8,
      "between_panels": 0.5,
      "post_scary": 0.6,
      "post_dm_glitch": 1.5,
      "post_caption_warning": 1.0
    }
  }
};