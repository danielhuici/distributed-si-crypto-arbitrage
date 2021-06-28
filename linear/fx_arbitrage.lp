max D
subject to
  D + DE + DP + DY - 0.8706 ED - 1.4279 PD - 0.00750 YD = 1
      ED + EP + EY - 1.1486 DE - 1.6401 PE - 0.00861 YE = 0
      PD + PE + PY - 0.7003 DP - 0.6097 EP - 0.00525 YP = 0
      YD + YP + YE - 133.33 DY - 116.14 EY -  190.48 PY = 0
bounds
  D <= 10000
end
