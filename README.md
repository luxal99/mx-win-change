# Few words about script
The main purpose of this script is dynamic changing rules for Mx Master mouses.

### Features
1. Change mx master mouse config depends on active app
2. When the chrome is active app, you're able to write config for each active app in tab
3. If you use two monitors, middle button is configured to change focus(cursor).

# Required software for normal usage
1. [Solaar](https://pwr-solaar.github.io/Solaar/) (min-version 1.1.8)
2. Python 3.8+
3. xdotool
````bash
sudo apt install xdotool
````
4. cnee
````bash
sudo apt install cnee
````
5. [BroTab](https://stackoverflow.com/questions/37524632/how-to-find-google-chrome-or-firefox-tab-url-by-terminalubuntu-or-windows)

# Configure permissions
First what you need to do, if you want to run Solaar and script on startup and without sudo is to give right privileges to some folders and files.

### Hidrwaw
On ubuntu find files /dev/hidraw* and change owner group or give it permission
```bash
sudo chmod 777 /dev/hidraw*
```
When you give non root permission to this files you're able to read data from Logi reciver from solaar without sudo

#### IMPORTANT

You need to give permission to 
````bash
sudo chmod 777 /dev/uinput
````
Problem with this permission is that you need to give it on each restart. Without it custom rules doesn't work.


Change permission of solaar folder

````bash
chown -R luxal:luxal /usr/share/solaar
````

# Configure Solaar

This script is in charge of dynamically changing the configuration of custom rules depending on the active app, but we need to somehow send notification to solaar to reload rules.

1. Open file /usr/share/solaar/lib/solaar/ui/window.py  
2. Copy code below
````python
import threading
import socket
from logitech_receiver import diversion as _DIV


def create_thread_for_reload_conf_socket():
    thread = threading.Thread(target=create_socket_listener_for_config_reloading)
    thread.start()

def create_socket_listener_for_config_reloading():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('127.0.0.1', 5555))
        s.listen()
        while True:
            conn, addr = s.accept()
            with conn:
              
                while True:
                    data = conn.recv(1024)
                    if not data:
                        break
                    
                    _DIV._load_config_rule_file()

````

When you create this two methods call it on init function

````python
# Method is already created just search for it
def init(show_window, hide_on_close):
....

if show_window:
        _window.present()
        create_thread_for_reload_conf_socket()

````

Now, we created solaar socket receiver, but we need client to send notification
For example, you can create somewhere in home directory file socket-reload.py and paste code below

````python
import socket
def client():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        # Socket is created on port 5555 but you can use any other free port
        s.connect(('127.0.0.1', 5555))
        s.sendall(b'Reload')

client()
````

Just few more steps... :)

1. Open mx-win-change.sh
2. Find a method reloadSolaar and write path of your socker-reload.py file
3. Set folder path where you store you mx-rules by changing the value of confFolderPath variable

# Create rules
Follow solaar documentation to write custom rules for your mouse and.
Whenever you save rule in app they will be save inside $HOME/.confg/solaar/rules.yaml
Copy content on that file for each app inside you folder for mx-rules
For example

1. Open solaar and write config for Spotify
2. Create file f.e spotify-rules.yaml somewhere in $HOME and paste to it content of rules.yaml
3. Then write rules for Chrome and when you finish paste it to f.e chrome-rules.yaml


# Run
1. Run solaar
````bash
solaar
````
2. Run script
````bash
bash mx-win-change.sh
````