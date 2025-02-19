source ~/.bashrc
source /opt/webapps/shell/server.sh

key="$name.jar"
runJar='/opt/webapps/'$name'.jar'

# skywalking
tenant_prefix=$(hostname | cut -d - -f 1)
skywalking_app_name=$tenant_prefix"_"$name
skywalking_cmd="-javaagent:/opt/webapps/skywalking-agent/skywalking-agent.jar -Dskywalking.agent.service_name=$skywalking_app_name"

PID=$(ps -ef | grep $key | grep -v grep | awk '{ print $2 }')
if [ ! -n "$PID" ]; then
  echo "服务$name已经被关闭..."
elif [ $name = "gameplat-web-server" ]; then
  # 关闭防火墙端口web-8090，阻断新的请求
  echo "关闭防火墙端口web-8090"
  sudo iptables -I INPUT -p tcp --dport 8090 -j REJECT
  # 等待60s，让进行中的线程执行完成，实现安全退出
  echo "关闭web服务倒计时 - 60s"
  sleep 15s
  echo "关闭web服务倒计时 - 45s"
  sleep 15s
  echo "关闭web服务倒计时 - 30s"
  sleep 15s
  echo "关闭web服务倒计时 - 15s"
  sleep 15s
  # 关闭web服务进程
  kill -9 $PID
  # 开启防火墙端口web-8090
  echo "开启防火墙端口web-8090"
  sudo iptables -D INPUT -p tcp --dport 8090 -j REJECT
else
  echo -n "开始关闭服务$name."
  wait_time=0
  kill -15 $PID
  # 每隔 2 秒检查一次是否进程仍在运行
  while kill -0 $PID 2>/dev/null; do
        sleep 2s
        wait_time=$((wait_time + 2))
        echo -n ".."
        if [ $wait_time -ge 60 ]; then
                kill -9 $PID
        fi
  done
  echo ""
fi

echo "开始重启服务$name..."


if [ ! -e "/opt/webapps/rasp/rasp.jar" ]; then
  nohup /opt/lucky/jdk/bin/java -jar -Xmx$vm -Xms$vm $runJar --spring.profiles.active=$profile >/dev/null 2>&1 &
elif [ $name = "gameplat-work-server" ]; then
  nohup /opt/lucky/jdk/bin/java -jar -Xmx$vm -Xms$vm $runJar --spring.profiles.active=$profile >/dev/null 2>&1 &
else
  nohup /opt/lucky/jdk/bin/java -Djava.io.tmpdir=/var/tmp  -javaagent:/opt/webapps/rasp/rasp.jar -jar -Xmx$vm -Xms$vm $runJar --spring.profiles.active=$profile >/dev/null 2>&1 &
fi
