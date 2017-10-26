#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH
echo "服务器提供商（host provider）[default:Enter]"
read hostp
echo "开始测试中，会需要点时间，请稍后"
#===============================以下是各类要用到的函数========================================
#teddey的besh测试网络下载和IO用到的
get_opsy() {
  [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
  [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
  [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
}

next() {
  printf "%-70s\n" "-" | sed 's/\s/-/g'
}

speed_test() {
  speedtest=$(wget -4O /dev/null -T300 $1 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}')
  ipaddress=$(ping -c1 -n `awk -F'/' '{print $3}' <<< $1` | awk -F'[()]' '{print $2;exit}')
  nodeName=$2
  if   [ "${#nodeName}" -lt "8" ]; then
    echo -e "$2\t\t\t\t$ipaddress\t\t$speedtest" | tee -a $logfilename
  elif [ "${#nodeName}" -lt "13" ]; then
    echo -e "$2\t\t\t$ipaddress\t\t$speedtest" | tee -a $logfilename
  elif [ "${#nodeName}" -lt "24" ]; then
    echo -e "$2\t\t$ipaddress\t\t$speedtest" | tee -a $logfilename
  elif [ "${#nodeName}" -ge "24" ]; then
    echo -e "$2\t$ipaddress\t\t$speedtest" | tee -a $logfilename
  fi
}

speed_test_v6() {
  speedtest=$(wget -6O /dev/null -T300 $1 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}')
  ipaddress=$(ping6 -c1 -n `awk -F'/' '{print $3}' <<< $1` | awk -F'[()]' '{print $2;exit}')
  nodeName=$2
  if   [ "${#nodeName}" -lt "8" -a "${#ipaddress}" -eq "13" ]; then
    echo -e "$2\t\t\t\t$ipaddress\t\t$speedtest" | tee -a $logfilename
  elif [ "${#nodeName}" -lt "13" -a "${#ipaddress}" -eq "13" ]; then
    echo -e "$2\t\t\t$ipaddress\t\t$speedtest" | tee -a $logfilename
  elif [ "${#nodeName}" -lt "24" -a "${#ipaddress}" -eq "13" ]; then
    echo -e "$2\t\t$ipaddress\t\t$speedtest" | tee -a $logfilename
  elif [ "${#nodeName}" -lt "24" -a "${#ipaddress}" -gt "13" ]; then
    echo -e "$2\t\t$ipaddress\t$speedtest" | tee -a $logfilename
  elif [ "${#nodeName}" -ge "24" ]; then
    echo -e "$2\t$ipaddress\t$speedtest" | tee -a $logfilename
  fi
}

speed() {
  speed_test 'http://cachefly.cachefly.net/100mb.test' 'CacheFly'
  speed_test 'http://speedtest.tokyo.linode.com/100MB-tokyo.bin' 'Linode, Tokyo, JP'
  speed_test 'http://speedtest.singapore.linode.com/100MB-singapore.bin' 'Linode, Singapore, SG'
  speed_test 'http://speedtest.london.linode.com/100MB-london.bin' 'Linode, London, UK'
  speed_test 'http://speedtest.frankfurt.linode.com/100MB-frankfurt.bin' 'Linode, Frankfurt, DE'
  speed_test 'http://speedtest.fremont.linode.com/100MB-fremont.bin' 'Linode, Fremont, CA'
  speed_test 'http://speedtest.dal05.softlayer.com/downloads/test100.zip' 'Softlayer, Dallas, TX'
  speed_test 'http://speedtest.sea01.softlayer.com/downloads/test100.zip' 'Softlayer, Seattle, WA'
  speed_test 'http://speedtest.fra02.softlayer.com/downloads/test100.zip' 'Softlayer, Frankfurt, DE'
  speed_test 'http://speedtest.sng01.softlayer.com/downloads/test100.zip' 'Softlayer, Singapore, SG'
  speed_test 'http://speedtest.hkg02.softlayer.com/downloads/test100.zip' 'Softlayer, HongKong, CN'
}

speed_v6() {
  speed_test_v6 'http://speedtest.atlanta.linode.com/100MB-atlanta.bin' 'Linode, Atlanta, GA'
  speed_test_v6 'http://speedtest.dallas.linode.com/100MB-dallas.bin' 'Linode, Dallas, TX'
  speed_test_v6 'http://speedtest.newark.linode.com/100MB-newark.bin' 'Linode, Newark, NJ'
  speed_test_v6 'http://speedtest.singapore.linode.com/100MB-singapore.bin' 'Linode, Singapore, SG'
  speed_test_v6 'http://speedtest.tokyo.linode.com/100MB-tokyo.bin' 'Linode, Tokyo, JP'
  speed_test_v6 'http://speedtest.sjc03.softlayer.com/downloads/test100.zip' 'Softlayer, San Jose, CA'
  speed_test_v6 'http://speedtest.wdc01.softlayer.com/downloads/test100.zip' 'Softlayer, Washington, WA'
  speed_test_v6 'http://speedtest.par01.softlayer.com/downloads/test100.zip' 'Softlayer, Paris, FR'
  speed_test_v6 'http://speedtest.sng01.softlayer.com/downloads/test100.zip' 'Softlayer, Singapore, SG'
  speed_test_v6 'http://speedtest.tok02.softlayer.com/downloads/test100.zip' 'Softlayer, Tokyo, JP'
}

io_test() {
  (LANG=en_US dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}
#=================teddey用到的函数结束=================================================

#=================以下是我自己写的网络mtr和ping用到的函数==============================

#测试来路路由
mtrgo(){
  mtrurl=$1
  nodename=$2
  echo "===测试 [$nodename] 到这台服务器的路由===" | tee -a $logfilename
  mtrgostr=$(curl -s "$mtrurl")
  #echo $mtrgostr >> $logfilename
  echo $mtrgostr > mtrlog.log
  mtrgostrback=$(curl -s -d @mtrlog.log "http://test.91yun.org/traceroute.php")
  rm -rf mtrlog.log
  echo -e $mtrgostrback | awk -F '^' '{printf("%-2s\t%-16s\t%-35s\t%-30s\t%-25s\n",$1,$2,$3,$4,$5)}' | tee -a $logfilename
  echo -e "=== [$nodename] 路由测试结束===\n\n" | tee -a $logfilename
}

#测试回程路由
mtrback(){
  echo "===测试 [$2] 的回程路由===" | tee -a $logfilename
  mtr -r -c 10 $1 | tee -a $logfilename
  echo -e "===回程 [$2] 路由测试结束===\n\n" | tee -a $logfilename

}

#测试全国ping值
pingtest(){
  echo "===开始进行全国PING测试===" | tee -a $logfilename
  pingurl="http://www.ipip.net/ping.php?a=send&host=$1&area%5B%5D=china"
  pingstr=$(curl -s "$pingurl")
  #echo $pingstr >> $logfilename
  echo $pingstr > pingstr.log
  pingstrback_all=$(curl -s -d @pingstr.log "http://test.91yun.org/ping.php?ping")
  pingstrback=$(curl -s -d @pingstr.log "http://test.91yun.org/ping.php")
  rm -rf pingstr.log
  echo "===all ping start===" >> $logfilename
  echo -e $pingstrback_all | awk -F '^' '{printf("%-3s\t%-30s\t%-15s\t%-20s\t%-3s\t%-7s\t%-7s\t%-7s\t%-3s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9)}' >> $logfilename
  echo -e "===all ping end===\n\n" >> $logfilename
  echo "===ping show===" >> $logfilename
  echo -e $pingstrback | awk -F '^' '{printf("%-10s\t%-10s\t%-30s\t%-10s\t%-30s\t%-30s\t%-30s\n",$1,$2,$3,$4,$5,$6,$7)}' | tee -a $logfilename
  echo -e "===ping show end===\n\n" >> $logfilename
  echo "===进行全国PING测试结束===" | tee -a $logfilename

}

#测试跳板ping
#参数1,ping的地址
#参数2,描述
testping()
{
  echo "{start testing $2 ping}" | tee -a $logfilename
  ping -c 10 $1 | tee -a $logfilename
  echo "{end testing}" | tee -a $logfilename
}
#==========================自用函数结束========================================

#获取各种系统信息
cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
tram=$( free -m | awk '/Mem/ {print $2}' )
swap=$( free -m | awk '/Swap/ {print $2}' )
up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60;d=$1%60} {printf("%ddays, %d:%d:%d\n",a,b,c,d)}' /proc/uptime )
opsy=$( get_opsy )
arch=$( uname -m )
lbit=$( getconf LONG_BIT )
host=$hostp
up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60;d=$1%60} {printf("%ddays, %d:%d:%d\n",a,b,c,d)}' /proc/uptime )
kern=$( uname -r )
ipv6=$( wget -qO- -t1 -T2 ipv6.icanhazip.com )
IP=$(curl -s myip.ipip.net | awk -F ' ' '{print $2}' | awk -F '：' '{print $2}')
IPaddr=$(curl -s myip.ipip.net | awk -F '：' '{print $3}')
if [ "$IP" == "" ]; then
  IP=$(curl -s ip.cn | awk -F ' ' '{print $2}' | awk -F '：' '{print $2}')
  IPaddr=$(curl -s ip.cn | awk -F '：' '{print $3}')
fi
backtime=`date +%Y%m%d`
logfilename="test91yun.log"
#查看虚拟化技术：
yum install -y gcc gcc-c++ gdb
wget http://people.redhat.com/~rjones/virt-what/files/virt-what-1.12.tar.gz
tar zxvf virt-what-1.12.tar.gz
cd virt-what-1.12/
./configure
make && make install
vm=`virt-what`
cd ..
rm -rf virt-what*


yum install -y mtr || { apt-get update;apt-get install -y mtr; } || { echo "mtr没安装成功，程序暂停";exit 1; }
yum -y install wget || {  apt-get update;apt-get install -y wget; } || { echo "wget没安装成功，程序暂停";exit 1; }
yum -y install curl || { apt-get update;apt-get install -y curl; } || { echo "curl自动安装失败，请自行手动安装curl后再重新开始";exit 1; }

#覆盖已有文件
echo "====开始记录测试信息====" > $logfilename

#把系统信息写入日志文件
echo "===系统基本信息===" | tee -a $logfilename
echo "CPU:$cname" | tee -a $logfilename
echo "cores:$cores" | tee -a $logfilename
echo "freq:$freq" | tee -a $logfilename
echo "ram:$tram" | tee -a $logfilename
echo "swap:$swap" | tee -a $logfilename
echo "uptime:$up" | tee -a $logfilename
echo "OS:$opsy" | tee -a $logfilename
echo "Arch:$arch ($lbit Bit)" | tee -a $logfilename
echo "Kernel:$kern" | tee -a $logfilename
echo "ip:$IP" | tee -a $logfilename
echo "ipaddr:$IPaddr" | tee -a $logfilename
echo "host:$hostp" | tee -a $logfilename
echo "uptime:$up" | tee -a $logfilename
echo "vm:$vm" | tee -a $logfilename
echo "he:$he" | tee -a $logfilename
echo -e "\n\n" | tee -a $logfilename



#开始测试带宽
echo "===开始测试带宽===" | tee -a $logfilename
wget -O speedtest-cli https://raw.githubusercontent.com/91yun/speedtest-cli/master/speedtest_cli.py 1>/dev/null 2>&1
python speedtest-cli --share | tee -a $logfilename
echo -e "===带宽测试结束==\n\n" | tee -a $logfilename
rm -rf speedtest-cli

#开始测试下载速度和IO性能
echo "===开始测试下载速度和IO性能===" | tee -a $logfilename
next

if  [ -e '/usr/bin/wget' ]; then
  echo -e "Node Name\t\t\tIPv4 address\t\tDownload Speed" | tee -a $logfilename
  echo "===star ipv4 download===" >> $logfilename
  speed && next
  echo -e "===end ipv4 download===\n\n" >> $logfilename

  # if [[ "$ipv6" != "" ]]; then
  # echo -e "Node Name\t\t\tIPv6 address\t\tDownload Speed" | tee -a $logfilename
  # echo "===star ipv6 download===" >> $logfilename
  # speed_v6 && next
  # fi
  # echo -e "===end ipv6 download===\n\n" >> $logfilename
else
  echo "Error: wget command not found. You must be install wget command at first."
  exit 1
fi

io1=$( io_test )
io2=$( io_test )
io3=$( io_test )
ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
[ "`echo $io1 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
[ "`echo $io2 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
[ "`echo $io3 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
ioavg=$( awk 'BEGIN{print '$ioall'/3}' )
echo "I/O speed(1st run) : $io1" | tee -a $logfilename
echo "I/O speed(2nd run) : $io2" | tee -a $logfilename
echo "I/O speed(3rd run) : $io3" | tee -a $logfilename
echo "Average I/O: $ioavg MB/s" | tee -a $logfilename
echo ""

#开始测试来的路由
mtrgo "http://www.ipip.net/traceroute.php?as=1&a=get&n=1&id=9&ip=$IP" "广州电信（超级信息港）"
mtrgo "http://www.ipip.net/traceroute.php?as=1&a=get&n=1&id=5&ip=$IP" "上海电信"
mtrgo "http://www.ipip.net/traceroute.php?as=1&a=get&n=1&id=12&ip=$IP" "重庆联通"
mtrgo "http://www.ipip.net/traceroute.php?as=1&a=get&n=1&id=2&ip=$IP" "天津移动"

#开始测试回程路由
mtrback "58.63.244.254" "广州电信（超级信息港）"
mtrback "222.73.199.97" "上海电信"
mtrback "113.207.32.65" "重庆联通"
mtrback "211.103.87.9" "天津移动"

#开始进行PING测试
pingtest $IP

#开始测试跳板ping
echo "===开始测试跳板ping===" >> $logfilename
testping speedtest.tokyo.linode.com Linode日本
testping hnd-jp-ping.vultr.com Vultr日本
testping 192.157.214.6 Budgetvm洛杉矶
testping downloadtest.kdatacenter.com kdatacenter韩国SK
testping 210.92.18.1 星光韩国KT
echo "===跳板ping测试结束===" >> $logfilename

#上传文件
resultstr=$(curl -s -T $logfilename "http://test.91yun.org/logfileupload.php")
echo -e $resultstr | tee -a $logfilename
