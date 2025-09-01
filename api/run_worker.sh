#!/bin/bash
# 脚本参数配置（按需修改）
PID_FILE="worker.pid"       # PID存储路径
LOG_FILE="worker.log"       # 日志文件路径
#CMD="uv run gunicorn -w 4 -b 0.0.0.0:5001 app:app"    # 需要执行的命令
CMD="uv run celery -A app.celery worker -P gevent -c 1 --loglevel INFO -Q dataset,generation,mail,ops_trace,app_deletion,plugin,workflow_storage,conversation" 
# 终止旧进程函数
# 终止旧进程函数
kill_old_process() {
    if [[ -f $PID_FILE ]]; then
        local old_pid=$(cat $PID_FILE)
        if ps -p $old_pid > /dev/null 2>&1; then
            echo "[$(date)] 终止旧进程 PID: $old_pid" | tee -a $LOG_FILE
            kill -SIGTERM $old_pid && sleep 2
            if ps -p $old_pid > /dev/null 2>&1; then
                kill -SIGKILL $old_pid
                echo "[$(date)] 强制终止 PID: $old_pid" | tee -a $LOG_FILE
            fi
        fi
        rm -f $PID_FILE
    fi
}

# 启动新进程
start_new_process() {
    nohup $CMD >> $LOG_FILE 2>&1 &
    echo $! > $PID_FILE
    echo "[$(date)] 启动新进程 PID: $(cat $PID_FILE)" | tee -a $LOG_FILE
}

# 主流程
kill_old_process
start_new_process
