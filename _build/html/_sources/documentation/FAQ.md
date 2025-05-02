# FAQ 

1. *My variable is not listed in the import dialog.*

Make sure the *.elf file is correct, and check the type of your variable - if it's a pointer it won't be detected. You can try making a new variable by right clicking in the variable table area and selecting New->Variable. Set the name manually and close the window. If the variable is detected the address will change from "NOT FOUND!" to a valid address.

2. *I'm using JLink probe and my target resets each time I start the acquisition.*

Make sure that the JLink probe SWD speed is not set to a too high value. Try lower speeds and make sure the "keep connection" from Acquisition window is checked.

2. *I'm using JLink probe and my target seems to halt for a few milliseconds each time I start the acquisition.*
   
Try selecting a generic device (eg. Cortex-M4 instead of STM32G474) and make sure the "keep connection" from Acquisition window is checked.

3. *The sampling frequency set in the Acquisition window is not reached.* 

If possible try selecting a higher SWD speed. If that's not possbile you can lower the sampling frequency or switch to a recorder module for high-frequency singnals. 
   






