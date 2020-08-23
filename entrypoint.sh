#!/bin/ash

##### Functions #####
Initialise(){
   lan_ip="$(hostname -i)"
   config_dir="/config"
   web_root="/airsonic"
   echo
   echo "$(date '+%c') INFO:    ***** Starting application container *****"
   echo "$(date '+%c') INFO:    $(cat /etc/*-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/"//g')"
   echo "$(date '+%c') INFO:    Username: ${stack_user:=stackman}:${user_id:=1000}"
   echo "$(date '+%c') INFO:    Password: ${stack_password:=Skibidibbydibyodadubdub}"
   echo "$(date '+%c') INFO:    Group: ${group:=airsonic}:${group_id:=1000}"
   echo "$(date '+%c') INFO:    Configuration directory: ${config_dir:=/config}"
   echo "$(date '+%c') INFO:    Application Directory: ${app_base_dir}"
   echo "$(date '+%c') INFO:    LAN IP: ${lan_ip}"
   echo "$(date '+%c') INFO:    Listening Port: ${listening_port:=4040}"
   echo "$(date '+%c') INFO:    Web root: ${web_root}"
   echo "$(date '+%c') INFO:    Airsonic Default Music Folder: ${airsonic_music:=/storage/music/}"
   echo "$(date '+%c') INFO:    Airsonic Default Podcast Folder: ${airsonic_podcast:=/storage/music/podcast/}"
   echo "$(date '+%c') INFO:    Airsonic Default Playlist Folder: ${airsonic_playlist:=/storage/music/playlists/}"
   echo "$(date '+%c') INFO:    Memory Limit: ${airsonic_memory_limit:=256}MB"
   if [ ! -d "${config_dir}/transcode/" ]; then mkdir "${config_dir}/transcode/"; fi
   if [ -f "/usr/bin/ffmpeg" ] && [ ! -L "${config_dir}/transcode/ffmpeg" ]; then ln -s "/usr/bin/ffmpeg" "${config_dir}/transcode/"; fi
   if [ -f "/usr/bin/lame" ] && [ ! -L "${config_dir}/transcode/lame" ]; then ln -s "/usr/bin/lame" "${config_dir}/transcode/"; fi
   if [ ! -d "${config_dir}/db/" ]; then mkdir "${config_dir}/db/"; fi
   if [ ! -f "${config_dir}/airsonic.properties" ]; then
      {
         echo "server.use-forward-headers=true"
         echo "GettingStartedEnabled=false"
         echo "WelcomeTitle=Welcome to Airsonic!"
         echo "WelcomeSubtitle="
         echo "WelcomeMessage2="
         echo "Theme=black"
         echo "LoginMessage="
         echo "IndexCreationInterval=1"
         echo "IndexCreationHour=6"
         echo "FastCacheEnabled=false"
      }  > "${config_dir}/airsonic.properties"
   fi
}

CheckOpenVPNPIA(){
   if [ "${openvpnpia_enabled}" ]; then
      echo "$(date '+%c') INFO:    OpenVPNPIA is enabled. Wait for VPN to connect"
      vpn_adapter="$(ip addr | grep tun.$ | awk '{print $7}')"
      while [ -z "${vpn_adapter}" ]; do
         vpn_adapter="$(ip addr | grep tun.$ | awk '{print $7}')"
         sleep 5
      done
      echo "$(date '+%c') INFO:    VPN adapter available: ${vpn_adapter}"
   else
      echo "$(date '+%c') INFO:    OpenVPNPIA is not enabled"
   fi
}

CreateGroup(){
   if [ "$(grep -c "^${group}:x:${group_id}:" "/etc/group")" -eq 1 ]; then
      echo "$(date '+%c') INFO:    Group, ${group}:${group_id}, already created"
   else
      if [ "$(grep -c "^${group}:" "/etc/group")" -eq 1 ]; then
         echo "$(date '+%c') ERROR:   Group name, ${group}, already in use - exiting"
         sleep 120
         exit 1
      elif [ "$(grep -c ":x:${group_id}:" "/etc/group")" -eq 1 ]; then
         if [ "${force_gid}" = "True" ]; then
            group="$(grep ":x:${group_id}:" /etc/group | awk -F: '{print $1}')"
            echo "$(date '+%c') WARNING: Group id, ${group_id}, already exists - continuing as force_gid variable has been set. Group name to use: ${group}"
         else
            echo "$(date '+%c') ERROR:   Group id, ${group_id}, already in use - exiting"
            sleep 120
            exit 1
         fi
      else
         echo "$(date '+%c') INFO:    Creating group ${group}:${group_id}"
         addgroup -g "${group_id}" "${group}"
      fi
   fi
}

CreateUser(){
   if [ "$(grep -c "^${stack_user}:x:${user_id}:${group_id}" "/etc/passwd")" -eq 1 ]; then
      echo "$(date '+%c') INFO     User, ${stack_user}:${user_id}, already created"
   else
      if [ "$(grep -c "^${stack_user}:" "/etc/passwd")" -eq 1 ]; then
         echo "$(date '+%c') ERROR    User name, ${stack_user}, already in use - exiting"
         sleep 120
         exit 1
      elif [ "$(grep -c ":x:${user_id}:$" "/etc/passwd")" -eq 1 ]; then
         echo "$(date '+%c') ERROR    User id, ${user_id}, already in use - exiting"
         sleep 120
         exit 1
      else
         echo "$(date '+%c') INFO     Creating user ${stack_user}:${user_id}"
         adduser -s /bin/ash -D -G "${group}" -u "${user_id}" "${stack_user}" -h "/home/${stack_user}"
      fi
   fi
}

SetOwnerAndGroup(){
   echo "$(date '+%c') INFO:    Correct owner and group of application files, if required"
   find "${app_base_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${app_base_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
   find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${config_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
}

RemoveLockFile(){
   if [ -f "${config_dir}/db/airsonic.lck" ]; then
      echo "$(date '+%c') WARNING: Lock file already exists. Previous shutdown was not clean. Removing lock file"
      rm "${config_dir}/db/airsonic.lck"
   fi
}

CreateLaunchScript(){
   {
      echo "#!/bin/ash"
      echo
      echo "$(which java) \\"
      echo "  -Dserver.port=${listening_port} \\"
      echo "  -Dserver.address=${lan_ip} \\"
      echo "  -Dserver.context-path=${web_root} \\"
      echo "  -Dairsonic.home=${config_dir} \\"
      echo "  -Xmx${airsonic_memory_limit}m \\"
      echo "  -Dairsonic.defaultMusicFolder=${airsonic_music} \\"
      echo "  -Dairsonic.defaultPodcastFolder=${airsonic_podcast} \\"
      echo "  -Dairsonic.defaultPlaylistFolder=${airsonic_playlist} \\"
      echo "  -Djava.awt.headless=true \\"
      echo "  -verbose:gc \\"
      echo "  -jar ${app_base_dir}/airsonic.war"
   } > /usr/local/bin/airsonic.sh
   chmod +x /usr/local/bin/airsonic.sh
}

LaunchAirsonic(){
   echo "$(date '+%c') INFO:    ***** Configuration of Airsonic container launch environment complete *****"
   if [ -z "${1}" ]; then
       echo "$(date '+%c') INFO:    Starting Airsonic as ${stack_user}"
      exec "$(which su)" -p "${stack_user}" -c "/usr/local/bin/airsonic.sh"
   else
      exec "$@"
   fi
}

##### Script #####
Initialise
CheckOpenVPNPIA
CreateGroup
CreateUser
SetOwnerAndGroup
RemoveLockFile
CreateLaunchScript
LaunchAirsonic