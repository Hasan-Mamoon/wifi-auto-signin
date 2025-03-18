# WiFi-auto-SignIn  

**Automated WiFi Login for FAST-NU Students**  

## Overview  
Following the recent firewall deployments at **FAST-NU**, connecting to the university WiFi has become a hassle due to frequent manual sign-ins. This repository automates the login process, making it seamless for students.


Currently tested and used for CFD Campus only!

---

## Linux Setup (The only OS currently supported):   

### 🔹 Step 1: Make the Script Executable  
```bash
chmod +x autologin-setup.sh
```

### 🔹 Step 2: Run the Setup (Only Once)

Ensure correct SSID inputs(case sensitive), for muliple networks give one network per line

```bash
sudo ./autologin-setup.sh
```
Follow the on-screen instructions, and voila you're done!!!  

---






## Modifying Login Details  

To change the **username/password** or **add more networks**, edit the configuration file:  
```bash
sudo nano /etc/wifi-auto-login.conf
```
Alternatively, use the GUI file manager:  
```bash
nautilus admin:/etc/wifi-auto-login.conf
```

---
    
