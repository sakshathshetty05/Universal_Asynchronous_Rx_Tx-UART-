UART Transmitter (Verilog)

What this is:
A simple UART transmitter written in Verilog.  
It takes a byte of data, adds start/stop bits, and sends it out serially.  
There’s also a testbench that shows how multiple bytes can be sent.

How it works:
- When idle, the TX line is high.  
- On start, the module loads {stop bit, data, start bit} into a shift register.  
- Each baud_tick, the least significant bit gets shifted out on tx.  
- After all bits are sent (1 start + 8 data + 1 stop), the line goes back high and the module is ready again.

process follows:
Idle → Start bit → Data bits → Stop bit → Idle

Testbench:
- Generates clock + baud pulses  
- Sends multiple bytes one after another  
- Dumps a waveform so you can watch the TX line toggle

