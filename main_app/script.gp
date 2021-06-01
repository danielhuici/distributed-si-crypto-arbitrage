set key left top
set grid xtics ytics
set xdata time
set title "BTC-USD"
set xlabel "Time (min)"
set ylabel "Profit"
set term png size '512,512'
set output "rand.png"
set timefmt "%m/%d/%y"
set xrange ["03/21/95":"03/22/95"]
set format x "%m/%d"
set timefmt "%m/%d/%y %H:%M"
plot "test.data" using 1:3