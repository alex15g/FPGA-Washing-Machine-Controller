# 🧺 Smart Washing Machine Controller (FPGA)

![VHDL](https://img.shields.io/badge/Language-VHDL-orange.svg) 
![FPGA](https://img.shields.io/badge/Platform-Vivado-blue.svg) 
![Hardware](https://img.shields.io/badge/Target-Nexys%20A7--100T-red.svg)

## 📖 Project Overview
This project implements the control logic for an automated washing machine using a complex **Finite State Machine (FSM)**. Developed in **VHDL** for the Artix-7 FPGA (Nexys A7), the system manages every stage of a laundry cycle—from user-defined parameter configuration to the final spin cycle and safety locking mechanisms.



## 🛠️ System Architecture
The design follows a modular (Top-Level Design) approach, consisting of the following interconnected units:

* **`Main_Controller`**: The central processing unit (FSM) managing states: *Idle, Temperature Setting, Speed Setting, Water Heating, Washing, Rinsing, and Spinning*.
* **`Timer_Unit`**: Responsible for frequency division (100MHz to 1Hz) and managing the MM:SS countdown.
* **`SSD_Driver`**: Seven-segment display driver using time-multiplexing to control all 8 digits.
* **`Input_Debouncer`**: Filter for physical buttons, eliminating contact "bouncing" and synchronizing asynchronous inputs.



## 🌟 Key Features
- ✅ **Dual Interface**: Support for both Automatic programs (5 presets: Cotton, Synthetics, Rapid, Delicate, Eco) and Manual mode.
- ✅ **Adjustable Parameters**: Temperature selection (**30°C - 90°C**) and spin speed (**800 - 1200 RPM**).
- ✅ **Safety System**: Electronic door lock and a 1-minute post-wash safety timer (cooling/unlocking phase).
- ✅ **Real-Time Feedback**: Progress monitoring and remaining time displayed on the SSD (minutes and seconds).

## 📊 FSM Implementation Details
The system utilizes a multi-state machine (**Moore Machine**) to ensure stable transitions:
1. **START/IDLE**: Checks door status and initializes system.
2. **CONFIG**: Captures user inputs for program type, temperature, and spin speed.
3. **WATER_HEAT**: Simulates water heating (duration scales with selected temperature).
4. **WASH/RINSE**: Repetitive cycles controlled by the `Timer_Unit`.
5. **SPIN**: High-speed rotation simulation (visualized via display frequency).
6. **END/LOCK**: Post-cycle safety delay before unlocking the door.

## 📂 Project Structure
Each file has a specific role in the hierarchy to ensure modularity and scalability:
* **`src/`**: Contains all VHDL source files.
* **`constr/`**: Contains the Xilinx Design Constraints (.xdc) file for pin mapping.
* **`docs/`**: Technical documentation, including state diagrams and user manual.


## 🚀 Getting Started in Vivado
To deploy this project on your Nexys A7 board, follow these steps:
1. **Initialize Project**: Create a new RTL Project in Vivado and select the `xc7a100tcsg324-1` part.
2. **Add Sources**: Import all `.vhd` files from the `src` folder.
3. **Add Constraints**: Import the `.xdc` file to map the internal signals to the physical buttons, LEDs, and SSD pins.
4. **Synthesis & Implementation**: Run the Synthesis and then the Implementation process to map the logic to the FPGA fabric.
5. **Bitstream Generation**: Generate the `.bit` file.
6. **Program Hardware**: Use the Hardware Manager to upload the bitstream to the board via USB.

