local _, addon = ...;

-- https://onlinetexttools.com/split-text?input=&split-by-char=false&char=%20&split-by-regex=false&regex=%2F%5Cs%2B%2F&split-by-length=true&length=110&separator=%2C%5Cn&symbol-before-chunk=%22&symbol-after-chunk=%22
table.insert(addon.officialCourses, table.concat({
    "!WOP:2!0x34B5C62D!fw5xOXrrCCCAsJjDJ)jPsAquSdAXheZL7I3TXeroAJTCwBQ1KuckwBMB2F7TJz2DwNz2C9QfvsRpzTIvqWhIpKhurqW2",
    "xuqbbFskkUivKIIVuFOTIiueTGi4V5YDX8Ntp4G9M93o)(9533F)(nZwERYmzIsdFG7zzYWybyaVGrs4EFsN9EQ7VuXl)rF25lS)9wQ4v(YFy2",
    ")(Z)(Rtvk(cuHhxBOrmORZYOcrzkBET7InFPZuvLkHNJkKhXdPXolhdknAeImbP9m33Yeav18Rhykd3ia1HK8idj3E8vii9nR1dePp5qu18iIX",
    "BVUprVDuotgDun)44ozk6XRnxC)nc0AmL29C7jaDO6GsI9PBAhbPD2iR(577f6BlF80LkE1TDSt)S3XSPBTR0UCtVjN0UDs7XjDBwktDgiT3gu",
    "ns6TKERP32aP9nxA)wFNU947EcbpSmXeaKQOgq84kGze1i0aG6Lz9b8Gp5B)BpZfqz87U6RTZ)OyBd4dU5aME7R3LNAPVyWtEgmh65iprhBv3w",
    "xMVf5WdpDivzijAAfWk2larva)ebrbgfqnegnIubmKAYeImYiX0LRjkP0Fdj4N(U)0j2Xflv8A5M6IV4R(7TLMcTGMjMKopydLcvuuhfYOk)R(",
    "Ibp0ANBi15aWhXwOT)vUaOIPA9gO68fQDId8xivlDJB8Yp9J3wQCBVSpWjFKZSVHrx(RlpU)4VEBD5OTirh9WAynnoatQOgUmsV2KKQXg3kb2N",
    "w1hReBi5255EPmxjej5Rp9((ZF8dBljpuli5iws2uvVjfRwk2SGhZfcQIy)yCvzQgAAPSibicKCZ659Yx7nF(R373uQ4V4((389U0XAlVJ1cEV",
    "Z9NegtOmLuRjnBhxHLnOoD2)5U0UkIr7cD)gVYxnZ)D0wSXbpzBr4EV6HRr2xMkWJxQrQgakGCaQGIrpIW1zCCEkScvfXGebGNDd2HMMvWgdoR",
    "vAwBv15Wnh)Mem0qPkoqINwwF2laeXRulS7)5AbnavxlJIzRB4oh8XO4zSkQGhvzOz4SazKNINOVhUx8UChTGVVRx2HG8E(dLVq5SdngZhgkFo",
    "w(CUU(5ZwiBCFcQ2ek94(CWZJAG4(ZMF4rChEKCKrYoEHSJNp3IHiOOnQB8oybufLza1E94gmQtu)(KoIVRvnONLBcw517wVBMHVa4SmxprJ7B",
    "cwgJLpNLim1kpj4Xtct7nEWj5AnosmozAdqfRk3lxvwDb7TjYOPglt2mfoVhOzkESD(j(DMX2pG)OKhfcLrKsjribKvUKdRt1TVYkIbLvS5rqz",
    "48wez6effpnKmb3u7bAUQ(wasfjIax3SW()3qyRBLbIgGiIVOgQjeQsMe5L5F("
}))
