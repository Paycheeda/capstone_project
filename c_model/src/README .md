README.TXT

Syed Muhammad Ahmed Ali
IC DESIGN SUMMER SCHOOL 2025
ahmedaligaming420@gmail.com

to run the packet parser , 
open terminal , go to the folder where cmodel is located
(cd ...../c_model/src)

run the following commands
make clean //just in case , skippable
make
./test

to get more number of packets open test.c 
goto line 12 (const int N = 5;)
change the value of N to whatver number you want

by default creates 5 packets and parses them.

HOW IT WORKS
1.test.c runs a loop 
2.each loop chooses a random number
3.checks if its even or odd
4.creates a ipv4 packet if even and ipv6 packet if odd
5.calls parser.c function which parses the packet and also displays it all

WAS GPT USED DURING THIS MAKING?
-Yes it was used to:
1.resolve errors, regarding function calls.
2.for creating Makefile. 
3.give the print function a more "clean look" on the output screen

rest of the functionality was written by me and was preserved during the gpt fixes.
most comments were added by me aswell.

May we all get hired at our designated jobs soon with peace and good being
Ameen

Syed Muhammad Ahmed Ali
IC DESIGN SUMMER SCHOOL 2025
ahmedaligaming420@gmail.com