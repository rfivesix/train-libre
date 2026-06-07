import os
import re

emoji_pattern = re.compile(
    "["
    "\U0001f600-\U0001f64f"  # emoticons
    "\U0001f300-\U0001f5ff"  # symbols & pictographs
    "\U0001f680-\U0001f6ff"  # transport & map symbols
    "\U0001f1e0-\U0001f1ff"  # flags (iOS)
    "\U00002700-\U000027bf"  # dingbats
    "\U00002600-\U000026ff"  # miscellaneous symbols
    "\U0001f900-\U0001f9ff"  # supplemental symbols and pictographs
    "\U0001fa70-\U0001faff"  # symbols and pictographs extended-a
    "\u200d"                 # zero width joiner
    "\u2640-\u2642"          # gender symbols
    "\u2600-\u2B55"          # other symbols
    "\u2139"                 # info symbol
    "\u26a0"                 # warning symbol
    "\U00002b50"             # star
    "\u23cf"                 # eject
    "\u23e9-\u23f3"          # forward/rewind/hourglass etc
    "\u23f8-\u23fa"          # pause/stop/play
    "\u25b6"                 # play triangle
    "\u25c0"                 # reverse triangle
    "\u2934-\u2935"          # arrow curves
    "\u2b05-\u2b07"          # arrows
    "\u2b1b-\u2b1c"          # square shapes
    "\u2b50"                 # star
    "\u2b55"                 # circle
    "\u3030"                 # wavy dash
    "\u303d"                 # part alternation
    "\u3297"                 # congrats
    "\u3299"                 # secret
    "]+", flags=re.UNICODE
)

search_dirs = [
    "/Users/richardgeorgschotte/Projekte/train-libre/docs",
    "/Users/richardgeorgschotte/Projekte/train-libre/lib"
]

for s_dir in search_dirs:
    for root, dirs, files in os.walk(s_dir):
        if "node_modules" in dirs:
            dirs.remove("node_modules")
        for file in files:
            if file.endswith((".html", ".css", ".js", ".dart")):
                path = os.path.join(root, file)
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        for line_num, line in enumerate(f, 1):
                            matches = emoji_pattern.findall(line)
                            if matches:
                                # Filter out common things if we want, or just print them all
                                print(f"{path}:{line_num} - Found: {matches} - Line: {line.strip()}")
                except Exception as e:
                    print(f"Error reading {path}: {e}")
