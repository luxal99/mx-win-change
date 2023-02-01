#!/bin/bash

# History of active apps. Whenever some new app is active they will pushed to array, 
#if some known app is active again they will be pushed to the last place

activeApplications=()

# Function which is triggered on mouse click
mouseupFunction() {
  activeApplication="$(cat /proc/$(xdotool getwindowpid $(xdotool getwindowfocus))/comm)"
  previousActiveApp=activeApplications[0]
  if [[ ${#activeApplications[@]} != 0 ]]; then
	previousActiveApp=${activeApplications[-1]}
  fi
  
  if [ "$activeApplication" != "$previousActiveApp" ]; then
    copyConfigDependsOnApp $activeApplication
  fi

  addActiveApplication $activeApplication

}
# Add new active app, or move known on last position
addActiveApplication() {
  potentialApp=$1
  if [[ ! "${activeApplications[*]}" =~ $potentialApp ]]; then
    activeApplications+=("${potentialApp}")
  else
    indexOfApp=0
    for i in "${!activeApplications[@]}"; do
      if [[ "${activeApplications[$i]}" = "${potentialApp}" ]]; then
        indexOfApp=$i
      fi
    done
    unset "activeApplications[$indexOfApp]"
    activeApplications+=("${potentialApp}")
  fi
}

# Send notification to reload solaar config file
reloadSolaar() {
python3 /home/luxal/mx-config/socket-reload.py
}

#Copy configuration
copyConfiguration() {
  cp $1 /home/luxal/.config/solaar/rules.yaml
}

# Decide which config will be set by app
copyConfigDependsOnApp() {
  activeApplication=$1
  case $activeApplication in
  chrome)
    copyConfiguration /home/luxal/mx-config/chrome-rules.yaml
    ;;
  java)
    copyConfiguration /home/luxal/mx-config/ws-rules.yaml
    ;;
  *)
    copyConfiguration /home/luxal/mx-config/rules.yaml
   ;;
  esac
   reloadSolaar

}

cnee --record --mouse |
  while read line; do
    if [ ! -z "$(echo "$line" | awk '/7,5,0,0,1/')" ]; then
      mouseupFunction
    fi
  done
