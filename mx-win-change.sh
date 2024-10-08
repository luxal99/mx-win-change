#!/bin/bash

# History of active apps. Whenever some new app is active they will pushed to array,
#if some known app is active again they will be pushed to the last place
activeApplications=()
activeChromeLinks=()
confFolderPath=/home/luxal/PC/MxConfig/mx-config

# Function which is triggered on mouse click
mouseupFunction() {
  activeApplication="$(cat /proc/$(xdotool getwindowpid $(xdotool getwindowfocus))/comm)"
  previousActiveApp=activeApplications[0]
  if [[ ${#activeApplications[@]} != 0 ]]; then
    previousActiveApp=${activeApplications[-1]}
  fi

  if [ "$activeApplication" != "$previousActiveApp" ] || [ "$activeApplication" = "chrome" ]; then
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
  python3 /home/luxal/PC/MxConfig/socket-reload.py
}

#Copy configuration
copyConfiguration() {
  confPath=$confFolderPath/$1
  cp $confPath /home/luxal/.config/solaar/rules.yaml
}

# Decide which config will be set by app
copyConfigDependsOnApp() {
  activeApplication=$1
  case $activeApplication in
  chrome)
    addActiveChromeLink "$(getUrlFromActiveChromeTab)"
    copyChromeConfigurationDependsOnLink
    ;;
  webstorm)
    copyConfiguration ws-rules.yaml
    ;;
  slack)
    copyConfiguration slack-rules.yaml
    ;;
  gjs)
    copyConfiguration system-rules.yaml
    ;;
  *telegram*)
    copyConfiguration telegram-rules.yaml
    ;;
  *teams*)
      copyConfiguration teams-rules.yaml
    ;;
  *postman*)
        copyConfiguration postman-rules.yaml
      ;;
  *)
    copyConfiguration rules.yaml
    ;;
  esac
  getActiveMonitor
  #changeMouseScrollMode
#  changeMouseVerticalScrollMode
  reloadSolaar

}

copyChromeConfigurationDependsOnLink() {
  currentLink="${activeChromeLinks[-1]}"
  previousActiveApp=activeChromeLinks[0]
  echo $currentLink
  case "${currentLink}" in
  *youtube*)
    copyConfiguration yt-rules.yaml
    ;;
  *meet*)
    copyConfiguration meet-rules.yaml
    ;;
  *teams*)
    copyConfiguration teams-rules.yaml
    ;;
  *zoom*)
      copyConfiguration meet-rules.yaml
      ;;
  *udemy*)
      copyConfiguration udemy-rules.yaml
      ;;
  *)
    copyConfiguration chrome-rules.yaml
    ;;
  esac
}

getUrlFromActiveChromeTab() {
  activeTabSessionNumber=$(bt active 2>&1 | grep -Eo "[A-Za-z].[0-9]{10}.[0-9]{10}")
  urlRegex="https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)"
  urlOfActiveTab=$(bt list | grep "${activeTabSessionNumber}" | grep -Eo "${urlRegex}")
  echo "${urlOfActiveTab}"
}

addActiveChromeLink() {
  potentialLink=$1
  if [[ ! "${activeChromeLinks[*]}" =~ potentialLink ]]; then
    activeChromeLinks+=("${potentialLink}")
  else
    indexOfLink=0
    for i in "${!activeChromeLinks[@]}"; do
      if [[ "${activeChromeLinks[$i]}" = "${potentialLink}" ]]; then
        indexOfLink=$i
      fi
    done
    unset "activeChromeLinks[$indexOfLink]"
    activeChromeLinks+=("${potentialLink}")
  fi
}

getActiveMonitor(){
  currentMonitorXCoordinates=$(xdotool getmouselocation --shell | grep X | cut -c 3-10)
  if [ $currentMonitorXCoordinates -gt 1920 ]; then
      changeMouseFocusIfYouAreOnRightMonitor
  else
    changeMouseFocusIfYouAreOnLeftMonitor
  fi
}

changeMouseFocusIfYouAreOnRightMonitor(){
  sed -i 's/2880/960/g' /home/luxal/.config/solaar/rules.yaml
}

changeMouseFocusIfYouAreOnLeftMonitor(){
  sed -i 's/960/2880/g' /home/luxal/.config/solaar/rules.yaml
}

changeMouseScrollMode(){
  currentMode=$(cat /home/luxal/.config/solaar/config.yaml| grep 'scroll-ratchet' | grep -Eiv 'sensitive' | cut -d ":" -f2)
  #  1 - FREESPINNING
  #  2 - RATCHETED
  if [ $currentMode = "1" ]; then
    sed -i 's/scroll-ratchet, 1/scroll-ratchet, 2/' /home/luxal/.config/solaar/rules.yaml
  fi

  if [ $currentMode = "2" ]; then
      sed -i 's/scroll-ratchet, 2/scroll-ratchet, 1/' /home/luxal/.config/solaar/rules.yaml
  fi

  echo $(cat /home/luxal/.config/solaar/rules.yaml)
}

changeMouseVerticalScrollMode(){
  currentMode=$(cat /home/luxal/.config/solaar/config.yaml| grep 'thumb-scroll-mode' | grep -Eiv 'sensitive' | cut -d ":" -f2)
  #  true - DIVERTED
  #  false - NO
  if [ $currentMode = "true" ]; then
    sed -i 's/scroll-ratchet, true/thumb-scroll-mode, false/' /home/luxal/.config/solaar/rules.yaml
  fi

  if [ $currentMode = "false" ]; then
      sed -i 's/scroll-ratchet, false/thumb-scroll-mode, false/' /home/luxal/.config/solaar/rules.yaml
  fi

  echo $(cat /home/luxal/.config/solaar/rules.yaml)
}

cnee --record --mouse |
  while read line; do
    if [ ! -z "$(echo "$line" | grep '7,5,0,0,1')" ]; then
      mouseupFunction
    fi
  done
