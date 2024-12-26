#!bin/sh

# PROVIDE: sftp_watchd
# REQUIRE: LOGIN
# KEYWORD: shutdown

. /etc/rc.subr

name="sftp_watchd"
rcvar="sftp_watchd_enable"

command="/usr/sbin/daemon"
pidfile="/var/run/sftp_watchd.pid"
executed_user="root"

start_cmd="${name}_start"
stop_cmd="${name}_stop"
restart_cmd="${name}_restart"
status_cmd="${name}_status"


sftp_watchd_start() {
        echo "Starting sftp_watchd."
        ${command} -c -f -P ${pidfile} -u ${executed_user} /usr/local/bin/sftp_watchd
}

sftp_watchd_stop() {
        if [ -f $pidfile ]; then
                pid=$(cat ${pidfile})
                echo "Kill: $pid"
                kill "$pid"
        fi
}

sftp_watchd_restart() {
        sftp_watchd_stop
        sftp_watchd_start
}

sftp_watchd_status() {
        pid=$(cat ${pidfile})
        echo "sftp_watchd is running as pid ${pid}."
}

load_rc_config $name
run_rc_command "$1"