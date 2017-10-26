#!/bin/bash
nginxdir=`find / -name nginx|grep nginx/sbin/nginx|awk -F sbin '{print $1}'`
while true
do
  clear
  # menu
  echo "
  本机Nginx路径为: $nginxdir"
  echo "
	****************** Nginx tool *******************
  *                                              *"
  echo "* (1)  启动Nginx                          *"
  echo "* (2)  关闭Nginx                          *"
  echo "* (3)  重启Nginx                          *"
  echo "* (4)  查看Nginx运行进程数                *"
  echo "* (5)  查看TCP连接状态                    *"
  echo "* (10) 添加虚拟主机                      *"
  echo "* (0)  退出本程序                        *"
  echo "*                                        *
  *************************************************"
  read -p  "请输入对应数字: " caozuo
  case $caozuo in
      # start
    1) if [ -z "`ps ax|grep nginx|grep -v grep|grep -v nginx.sh|awk '{print $1}'`" ];
      then
        $nginxdir/sbin/nginx
        sleep 1
        if [ -z "`ps ax|grep nginx|grep -v grep|grep -v nginx.sh|awk '{print $1}'`" ];
        then
          read -p "Nginx 启动失败！"
        else
          read -p "Nginx 启动完成！回车继续！"
        fi
      else
        read -p "Nginx is Running! 回车继续！"
      fi
      ;;
      #stop
    2) killall nginx
      sleep 1
      if [ -z "`ps ax|grep nginx|grep -v grep|grep -v nginx.sh|awk '{print $1}'`" ];
      then
        read -p "Nginx关闭完成！回车继续！"
      else
        read -p "Nginx关闭失败！回车继续！"
      fi
      ;;
      #restart
    3) if [ -z "`ps ax|grep nginx|grep -v grep|grep -v nginx.sh|awk '{print $1}'`" ];
      then
        $nginxdir/sbin/nginx
        read -p "Nginx启动完成！回车继续！"
      else
        killall nginx
        sleep 1
        $nginxdir/sbin/nginx
        read -p "Nginx重启完成！回车继续！"
      fi
      ;;
      #process
    4) read -p "Nginx运行进程数： `ps -ef|grep nginx|grep -v nginx.sh|grep -v grep|wc -l`"
      ;;
      #TCP
    5) read -p "TCP连接状态:
      `netstat -n | awk '/^tcp/ {++state[$NF]} END {for(key in state) print key,"t",state[key]}'`"
      ;;
      #vhost
    10)
      while true
      do
        clear
        read -p "请输入要添加的虚拟主机完整域名: " vhost
        read -p "请输入该域名使用的端口: " prot
        read -p "请输入域名对应的root目录: " hostdir
        read -p "请输入访问日志目录: " logdir
        echo "
																																																		    ################### 确认以下信息 ########################
        "
        read -p "Nginx的目录为:        $nginxdir
																																																		    要添加的虚拟主机为:    $vhost
																																																		    该域名对应的端口为:    $prot
																																																		    域名对应的root目录为:  $hostdir
																																																		    访问日志文件为:        $logdir/$vhost.log
																																																		    #########################################################
        [回车继续，如有误请输入0返回]:" queren2
        case $queren2 in
          0) break
            ;;
          *)
            mkdir $nginxdir/conf/vhost
            touch $nginxdir/conf/vhost/$vhost.conf
            sed -i "/include * mime.types/ a \include $nginxdir\/conf\/vhost\/$vhost.conf;" $nginxdir/conf/nginx.conf
            echo 'server
																																																																			      {
																																																																				        listen      '$prot';
																																																																					  server_name  '$vhost';
																																																																					    index index.php index.html index.htm;
																																																																					      root  '$hostdir';
																																																																					      location / {
																																																																					              if (!-e $request_filename){
																																																																							                rewrite ^(.*)$ /index.php?s=/$1 last;
																																																																									          rewrite ^(.*)$ /index.php/$1 last;
																																																																										          }
																																																																											          }
																																																																												      location ~ .*\.(php|php5)?$
																																																																												          {
																																																																														            fastcgi_pass  127.0.0.1:9000;
																																																																															              fastcgi_index index.php;
																																																																																      #          include fcgi.conf;
																																																																																              }
																																																																																	          location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$
																																																																																		      {
																																																																																			            expires      30d;
																																																																																				        }
																																																																																					    location ~ .*\.(js|css)?$
																																																																																					        {
																																																																																							      expires      1h;
																																																																																							          }
																																																																																								  access_log '$logdir/$vhost.log';
            }' >>$nginxdir/conf/vhost/$vhost.conf
            read -p "添加完成,需重启Nginx生效,回车返回!"
            break
            ;;
        esac
      done
      ;;
    0) break
      ;;
    *) read -p "请输入对应数字!或者Ctrl+C退出!回车继续!"
      ;;
  esac
done
