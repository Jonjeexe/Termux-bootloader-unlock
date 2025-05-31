# Termux bootloader Unlock
This tool help user to unlock there phones bootloader without pc and any hard process it had in-build simple guide and automatically do everything.

`Note: This tool cannot bypass the 7, 14, 30 day unlock time.`

## Requirements for Xaiome devices
1) Verified Xiaomi Account
2) Two Android device (Host & Target)
3) USB Otg & Data cable
4) Internet Connection



## Tool Installation 
1) Install required apps [termux universal](https://github.com/Jonjeexe/Termux-bootloader-unlock/releases/download/v1.0/termux-app-v0.118debug-universal.apk)  [termux-api](https://github.com/Jonjeexe/Termux-bootloader-unlock/releases/download/v1.0/termux-api-v0.50.1.apk) and [Mi Account](https://github.com/Jonjeexe/Termux-bootloader-unlock/releases/download/v1.0/Mi-Account.apk) on your host device.

2) Login and bind your xiaomi account on your target device.

3) Update termux packages
```console
pkg update && upgrade 
```
4) Install Git in termux
```console
pkg install git -y
```
5) Install vim in termux
```console
pkg install vim -y
```
6) Clone the repo
```console
git clone https://github.com/Jonjeexe/Termux-bootloader-unlock && cd Termux-bootloader-unlock
```
7) Open Tool
```console
chmod +x setup.sh && ./setup.sh
```
## Re-open Tool
`If Tool is already installed then do this step to open again `

1) Enter Tool folder
```console
cd Termux-bootloader-unlock
```
2) Open Tool
```console
./setup.sh
```

## NOTE
After Unlock bootloader device will factory reset already 