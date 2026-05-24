import os
base = os.path.dirname(os.path.abspath(__file__))
path = os.path.join(base, "config", "config-trucking.lua")
repls = [
    ('name = "\u4ee5\u5229\u897f\u5b89\u5c9b",', 'name = "Elysian Island",'),
    ('name = "\u6e2f\u53e3\u96c6\u88c5\u7bb1\u573a",', 'name = "Port container yard",'),
    ('name = "\u7801\u5934 - \u8d27\u8fd0\u4ed3\u5e93",', 'name = "Docks - freight warehouse",'),
    ('name = "\u67cf\u6811\u5e73\u5730 - RON\u4ed3\u50a8",', 'name = "Cypress Flats - RON storage",'),
    ('name = "\u67cf\u6811\u5e73\u5730 - \u5de5\u4e1a\u56ed\u533a",', 'name = "Cypress Flats - industrial park",'),
    ('name = "\u62c9\u6885\u8428 - \u7269\u6d41\u4e2d\u5fc3",', 'name = "La Mesa - logistics hub",'),
    ('name = "\u57c3\u5c14\u5e03\u7f57\u9ad8\u5730 - \u4ed3\u50a8\u8bbe\u65bd",', 'name = "El Burro Heights - storage facility",'),
    ('name = "\u6d1b\u5723\u90fd\u56fd\u9645\u673a\u573a - \u8d27\u8fd0\u7ad9",', 'name = "LSIA - freight terminal",'),
    ('name = "\u5927\u585e\u8bfa\u62c9\u6c99\u6f20 - \u7269\u6d41\u67a2\u7ebd",', 'name = "Grand Senora Desert - logistics hub",'),
    ('name = "\u6851\u8fea\u6d77\u5cb8 - \u5de5\u4e1a\u573a\u5730",', 'name = "Sandy Shores - industrial site",'),
    ('name = "\u5e15\u83b1\u6258\u6e7e - \u8d27\u8fd0\u573a",', 'name = "Paleto Bay - freight yard",'),
    ('name = "\u4e1c\u74e6\u6069\u4f0d\u5fb7 - \u8fdb\u53e3\u8bbe\u65bd",', 'name = "East Vinewood - import facility",'),
    ('name = "\u7a46\u5217\u5854\u9ad8\u5730 - \u914d\u9001\u4e2d\u5fc3",', 'name = "Murrieta Heights - distribution centre",'),
    ('name = "\u6d77\u76d7\u6e7e",', 'name = "Buccaneer Way",'),
]
with open(path, "r", encoding="utf-8") as f:
    s = f.read()
for a, b in repls:
    s = s.replace(a, b)
with open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write(s)
print("OK")
