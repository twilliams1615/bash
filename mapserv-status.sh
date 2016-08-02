#######################################################################################
### Check Mapserver status. If it returns a 200 status, then sleep for 10 seconds   ###
### If the status is anything else (usually 500), then restart the mapserver        ###
### service from supervisord, and send an email.                                    ###
### Requires a tile to be used                                                      ###
#######################################################################################

email="insert email address"
while true
do
    datefile=$(date +"%m%d%Y%H%M%S%N")
    for file in `ls /data/test-data/`; do
	mv /data/test-data/$file /data/test-data/$datefile.png
    done

    status=`wget --spider -S --timeout=4 "http://localhost:81/map/?map=/data/config-files/map01.map&mode=tile&map.layer[0]=data+/data/test-data/$datefile.png&tile=0+0+0" 2>&1 | grep "HTTP/" | awk '{print $2}'`
    logs="/local-project/supervisor_shared/logs/mapserv/mapserv-restart.log"

    if [ "$status" = "200" ]
    then
	sleep 5
    else
	supervisorctl restart mapserv:*
	echo "$(hostname) restarted mapserver at $(date) for status $status" >> $logs
	tail -n1 $logs | mail -aFrom:mgoldman@iteris.com -s "$(hostname) http status is $status" $email
	sleep 5
    fi
    done
