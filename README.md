# 🧺 Smart Washing Machine Controller (FPGA)

![VHDL](https://img.shields.io/badge/Language-VHDL-orange.svg) 
![FPGA](https://img.shields.io/badge/Platform-Vivado-blue.svg) 
![Hardware](https://img.shields.io/badge/Target-Nexys%20A7--100T-red.svg)

## 📖 Descrierea Proiectului
Acest proiect implementează logica de control pentru o mașină de spălat automată, utilizând un **Automat Finit (FSM)** complex. Sistemul este dezvoltat în **VHDL** pentru FPGA (Artix-7) și gestionează toate etapele unui proces de spălare, de la configurarea parametrilor de către utilizator până la ciclul final de centrifugare și siguranță.



## 🛠️ Arhitectura Sistemului
Design-ul este modular, fiind compus din următoarele unități interconectate:

* **`Main_Controller`**: Unitatea centrală (FSM) care gestionează stările: *Idle, Setare Temperatură, Setare Viteză, Încălzire, Spălare, Clătire, Centrifugare*.
* **`Timer_Unit`**: Modul responsabil pentru divizarea frecvenței ceasului de 100MHz și gestionarea numărătorii inverse (MM:SS).
* **`SSD_Driver`**: Driver pentru afișajul cu 7 segmente, utilizând multiplexarea în timp pentru a afișa datele pe 8 cifre.
* **`Input_Debouncer`**: Filtru pentru butoanele fizice, eliminând fenomenul de "bouncing" și sincronizând intrările asincrone.



## 🌟 Funcționalități
- ✅ **Interfață Duală**: Suport pentru programe automate (5 presetări) și mod manual.
- ✅ **Parametri Ajustabili**: Selecție temperatură (30°C - 90°C) și viteză de centrifugare (800 - 1200 RPM).
- ✅ **Sistem de Siguranță**: Blocare electronică a ușii și temporizare post-spălare de 1 minut.
- ✅ **Afișaj în Timp Real**: Monitorizarea progresului și a timpului rămas pe display-ul SSD (minute și secunde).

## 📂 Structura Fișierelor
```text
├── src/
│   ├── Main_Controller.vhd    # Logica principală (FSM)
│   ├── Timer_Unit.vhd         # Gestiune timp (ex: ceas.vhd)
│   ├── SSD_Driver.vhd         # Controler afișaj (ex: SSD.vhd)
│   └── Input_Debouncer.vhd    # Filtrare butoane (ex: MPGLISMAN.vhd)
├── constr/
│   └── NexysA7_Master.xdc     # Maparea pinilor hardware
└── README.md
