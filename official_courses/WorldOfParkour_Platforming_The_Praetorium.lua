local _, addon = ...;

-- https://onlinetexttools.com/split-text?input=&split-by-char=false&char=%20&split-by-regex=false&regex=%2F%5Cs%2B%2F&split-by-length=true&length=110&separator=%2C%5Cn&symbol-before-chunk=%22&symbol-after-chunk=%22
table.insert(addon.officialCourses, table.concat({
    "!WOP:2!0xD3E05B04!nI1xSXXrzC124MWgAjPvPvQqOtQIKDGZBV7SVl2ji568h8LGGA5AQfQisMDV5UD8T3otNz2765QkHsrcecesH)ubp5A1",
    "xQAfGQekbEGgjEiiOfTQ0(qRe)5ba1Ge5biQnQsLY3mZU7DN91E8KZTZUZ333VF)((9ntULFKNplwijVv1l6ZAZdjks9GYX06x(227HpATf(BU",
    "VW)6hs)g1w4nJFLn)EpZR8VXcbTdoSovQWr(KjUOpom0d73sw9czp0r0MgrBJ5oR0LjcR7SfNiKWIKivqYUp)R5hsWIS3(aROOQqIyzgnsHkDI",
    "gcir23A6peXAGwglAbPi)UmBfSPNJ6ZIoNKUb8L(c8g9opF)PXBGLs2Z5praSH8h6ruyHcHvivabDswKKi6GvmHEZ1pArHpoIua9fX(tUOGqqk",
    "siHZGVHRZi3Qj3AqYTLIh)97zJN87(4psTf(J)3h7VE8F7tLSRjsMOAYT7KSBNK94K8X01xIZbs2BA9uo5osUZKpXbs235t2VoRsUl(HwJmzyi",
    "YJ0KgzsbEiw1GPrTMOaIGSTyE)lnZZ9L(51w41XpWtDZdEZXgZzgrmN)lljMyfsQ3KirybloQo8eQ(FtWifd1KOqSifJNbnDbUD4C5FCFV0p53",
    "8NVmu)tn3wF2p3eJnxMDe5YlSsCechYGQnlkO1JBZ1LFEEbOcnmelKzzg8h9tJipHcjj(kklsNNMCe9vyXiGgrQECQwr2dPfxGaYcWRhdvwSsM",
    "9BjTor)XeSFqwXMfopIQlHez2y52Q(nVX1E5FW5GQ)DV4Rp73(pm2QVYiQ(YAMOhiPZRzzli0YrWaa3Stk4TFMZ(NUYI7hKdp77D9L(lF)XMev",
    "3zs8e3YNEvTqd4Eeyaa99qG6nukydpvgcWybD(AXxrV80w3O2Navb40oguf4ZG9OakwAOuieT9y6s6u1qypAivrHqp1PyXEqKplSFfqpkjQjPr",
    "CiAfIc0JQcOppb(rSmOaAPqGV6)GJ464Kr44qjdIdbHJ6H8IPGZuuZ8cXpKbT7zshBXaem0RzOauBCRb4ceRd8Y7Sb8T)pj9M4vNhq8t)(F1lE",
    "1Rowe)OJG2)cRcqNfq05ING1cezBtJNc8euDIujy9i1rANOuP(OBjVMh)RDPV5g1w4n29Uw4hFKF)yZU5gLEykJEqBfaGcaLBxomKNGLSncelJ",
    "B4BxxxKJZdhz0sOUS4qnwNTjyjkG2mq)3mXuAZyguSZcfPPRozcdHvy0hKgcdT5eKiWiGiWEaGU0xtVtfs7MO6nnmK11KeWleG7y9fdiq2zCzi",
    "yjnSxQI4J2o8AV1b)v39w)Aqz8Tw7mp9h)xowSF(rOmU3ZMR9YA7grKU(gx74V3KqKEOFXRw4o4F4r6cPdslocAExV4Q2UABjddHbDwghAzd75",
    "baU02JzqSiIfnfg)Y8PidJoP0a2JLIOMIWXzzMus9Som5E5qwCmNsUOLgqzKkhSeFUkX6TBtdMI6tsj6gMxqatsI5dqZPF1KkROZOvTHogmzsR",
    "XgmTeWy9QiCzb0z0ZJHnOLvweadH0s1btz7ceadaelxq0BWOJ6gqb8jfDBrY(wLos5Qwl0112Rb(PghHSrCUoLD7BfMP41TbzMFi9HT6cmNS)w",
    "Mc9moNjPkl6ZI(qcI(RCDMzySFOUYmvODBDDM19JWDwhSi0APUU2eZWqXC4uFTzA9L(ayd2w3vNAqIXeu4iq9hxBXjDVQEv9jtqsol)WBqhIgs",
    "5aotsnWn6cJtpow3(cUqObL4gsqNnd05hVt7wdN46uXf9WWjsn7Sg4Y3uZlzki0iROc9tMSELbgUz4plcbtESq0uyT4jFeQfQpsH(nieBKS2sf",
    "SO8Jht9BbG12zJb0et1NdY3v9M6JvyECOrhd93HngU5nfaCodQvearPZ(1hsdITxScL5U2nOx)vnoiPoghYI7gmGlyEypirv65RswBqdsBtm4a",
    "xG91TX2TToZ0Qs7OHxtR(KPekvDOHma)N7zZB8gBDbWa0j8jF(R80J3aS0i8ANCP(NKul87B)LsYPA(H9EV0N5D8p4TxBHxR4Kv)PFYF24d9Oo",
    "1)x))JZ9z5cg0CmKeRHUjjl1q6dsKQUwp)OtIX2DUTA6M)UI3zPNdQPMLE5d)MFW4RPrDRIVt2Tkeu7TkSk3DovOVjQv8LwQWlQ7xHu0ibGLnR",
    "IHQpNr0AB4CeqVOm7qBWH3b5b60rRZ6zDgOKUUVemmZxq56trW3C1Cr6PiTHTQwCKcG10XBooM1T)YitL6BHb9(qGZVjimUyrrZyPl6e24qIm3",
    "jLQmn8zsvOyKeRJBAv7P1v6KsQFIDpCCoPGuNQogAzAZM9EaAD(HRuU6mZwSI30ZvSmE6zl2OY0ZvYhpDrF8mvMVuv)5QI57lelvTz1PnOK61X",
    "WeR9xCMhS88py5sGi)yvo6XknZfAtuyynCv(94dDLqpgrCAiAaZFstrER8pv(cY1OQa7JxuUi0o2H4SfvEY0)hac2cIvdQpyx07e1Gw8K9YVVL",
    "h4oQaJHwwGjWTOPXT3QlRBh9f8zrRmVBr3kcFTiKj437zWWn(f4q4JMEvy2ilQo8fY)3"
}))
