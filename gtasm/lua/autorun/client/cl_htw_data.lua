page_list = {}

page_list["main.txt"] = [[
<html>
<head>
</head>
<iframe srcdoc="!list!" src="no.html" width="30%" height="100%" align="left"></iframe>
<iframe srcdoc="!page!" src="no.html" width="65%" height="100%" align="left"></iframe>
</html>
]]

page_list["list.txt"] = [[
<html>
<head>
</head>
<body>
<h2>gTASM language</h2>

<dl compact>
<dt>Guide to working with the programming language 'gTASM'
</dl>
<dl compact>
<dt><b>For newbies</b>
<dt>1. <a href=javascript:dhtw.changePage('start')>Start!</a>
<dt>2. <a href=javascript:dhtw.changePage('syntaxis')>Syntaxis</a>
<dt>3. <a href=javascript:dhtw.changePage('memory')>How memory works. Blocks of memory</a>
</dl>

<dl compact>
<dt><b>Starting to program</b>
<dt>4. <a href=javascript:dhtw.changePage('math_oper')>Math operations</a>
<dt>5. <a href=javascript:dhtw.changePage('labels')>About labels JMP</a>
<dt>6. <a href=javascript:dhtw.changePage('cmp_guide')>Branching the program. CMP</a> 
<dt>7. <a href=javascript:dhtw.changePage('stack')>Stack. PUSH and POP</a>
<dt>8. <a href=javascript:dhtw.changePage('sysinterrupt')>Interrupts. <b>HELLO WORLD</b> and other</a>
</dl>

</body>
]]

page_list["start.txt"] = [[
<html>
<head>
<base target=guide>
</head>
<body>
<h2>WELCOME to the guide</h2>
<p>This guide aims to somehow learn how to program in gTASM</p>

<p>gTASM is a simplified version of the Assembler language. It aims to turn an ordinary dummy terminal into an effective tool for various purposes.</p>

Using gTASM, we can turn a computer into:
<ul>
<li>Calculating machine with office software</li>
<li>Arcade machine</li>
<li>BBS Server</li>
<li>And other things...</li>
</ul>

<h3>Preparing the system</h3>
<p>In conventional systems such as Personal and Server, we will not be able to program. We need a <b>ptsm</b> OS system. Just enter it into a new computer:</p>
<pre>
:os install ptsm 
</pre>
<p>The new system is endowed with new utilities such as a code editor(:f dr) and a disk(:d). their use is well described in the description of the commands.</p>


]]

page_list["syntaxis.txt"] = [[
<html>
<head>
<base target=guide>
</head>
<body>
<h2>Syntaxis</h2>
<p>The syntax of the commands here is quite simple. I'll show you by example:</p>
<pre>OPER VAR, VAR2, VAR3, ...</pre>
<p>This example shows that the main command comes first, then the arguments come. Here is a real example:</p>
<pre>mov R1, 3</pre>
<p>This command transfers the value 5 to the R1 register.</p>
<h4>Labels</h4>
<p>Labels are defined by the name with colons at the end</p>
<pre>
...
myGoodLabel:
...</pre>
<p>Also, the label ONLY needs the db command to give it a name:</p>
<pre>
someString: db 'Some string',0  #with label
db 'ABC',0 #without label
</pre>
<h4>Variables</h4>
<dl compact>
<dt><b>Registers</b> are needed for quick access to memory and are written simply: <code>R1,R2,R3...</code>
<dt><b>Strings</b> are strings: <code>'The text'</code>
<dt><b>Numbers</b> can be written in decimal, binary, and hexadecimal: <code>123, 0b0101, 0xA0</code>
<dl>
EX:
<pre>
Text: db 'Hello World!'
mov R3, 0x5A
add R1, 0b10
</pre>
<p><b>Addresses</b> are a special kind of values. They are a direct reference to a memory cell. here is an example of writing:</p>
<pre>
mov [40], 42     # [ var ]  is addres
mov [R2], 0x3
mov R4, [DBNAME]
</pre>
<h3>Comments</h3>
<pre>
mov R1,10   # COMMENT
</pre>
<h3>Line break</h3>
<p>A line break <b>;></b> is needed to point to the next line. Convenient for db command</p>
<pre>
ASCII: db >;
' _  __ ________', ;>
'|_|(_ /   |  |', ;>
'| |__)\___|__|_'
</pre>
]]

page_list["not_found.txt"] = [[
<html>
<head>
<base target=guide>
</head>
<body>
Not found page
]]

page_list["memory.txt"] = [[
<html>
<head>
<base target=guide>
</head>
<body>
<h2>Memory</h2>
<p>Memory is needed to store data for the program. It is divided into blocks and their sizes are strictly defined. In the basic version, their size is 40 bytes. There are only 6 blocks:
<dl compact>
<dt>1.<b>REGISTR</b></a>
<dt>2.<b>STACK</b></a>
<dt>3.<b>SERVICE</b></a>
<dt>4.<b>POOL1</b></a>
<dt>5.<b>POOL2</b></a>
</dl>
</p>
<p>In general, memory can be represented as a huge table with data written into it.</p>

<table border='1' style='border-collapse:collapse;' cellpadding='5'><tbody>
    <tr>
        <td>№ Cell - Address</td>
        <td>Data</td>
    </tr>
    <tr>
        <td>0</td>
        <td>00000000</td>
    </tr>
    <tr>
        <td>1</td>
        <td>00000101</td>
    </tr>
    <tr>
        <td>2</td>
        <td>00010110</td>
    </tr>
    <tr>
        <td>3</td>
        <td>00000000</td>
    </tr>
    <tr>
        <td>4</td>
        <td>00000000</td>
    </tr>
    <tr>
        <td>...</td>
        <td>...</td>
    </tr>
</table>
<p>As can be understood from this table, the cell has a size of 1 byte. This is enough to write a number from 0 to 255 and one ASCII encoding letter. Negative numbers CANNOT be written down. The total size of the entire memory is 6 * 40 = <b240</b> bytes</p>
<h3>Abouts blocks</h3>
<p>1. <b>REGISTR</b> is needed to store important program data. It is in it that registers and flags are already predefined. List of Registers and flags</p>
<table border='1' style='border-collapse:collapse;' cellpadding='5'><tbody>
    <tr>
        <td>Name of Register</td>
        <td>Addres</td>
    </tr>
    <tr>
        <td>R1</td>
        <td>0</td>
    </tr>
    <tr>
        <td>R2</td>
        <td>2</td>
    </tr>
    <tr>
        <td>R3</td>
        <td>4</td>
    </tr>
    <tr>
        <td>R4</td>
        <td>6</td>
    </tr>
    <tr>
        <td>R5</td>
        <td>8</td>
    </tr>
    <tr>
        <td>R6</td>
        <td>10</td>
    </tr>
    <tr>
        <td>R7</td>
        <td>12</td>
    </tr>
    <tr>
        <td>R8</td>
        <td>14</td>
    </tr></tbody>
</table>

<table border='1' style='border-collapse:collapse;' cellpadding='5'><tbody>
<tr>
<td>Name of flag</td>
<td>Addres</td>
</tr>
<tr>
<td>IP</td>
<td>31</td>
</tr>
<tr>
<td>SP</td>
<td>32</td>
</tr>
<tr>
<td>CF</td>
<td>33</td>
</tr>
<tr>
<td>ZF</td>
<td>34</td>
</tr>
<tr>
<td>CF</td>
<td>35</td>
</tr>
<tr>
<td>INP</td>
<td>36</td>
</tr>
<tr>
<td>INK</td>
<td>37</td>
</tr>
<tr>
<td>INS</td>
<td>38</td>
</tr>
</table>

<p>2.<b>STACK</b> is needed for temporary data storage. You will learn about it from another file.</p>
<p>3.<b>SERVICE</b>block is needed to access the system and call interrupts. See INT</p>
<p>4.<b>POOL1</b> For storing information. It is in it that the DB recording begins</p>
<p>5.<b>POOL2</b> The same thing</p>


<p>To address directly to the memory address, оust write the value inside the square brackets:</p>
<pre>
mov [14], 7
mov [R1], 230    # read value from R1
mov R2, [SOMEDB] # get start addres of SOMEDB
</pre>

<h3>MOV and DB</h3>
<p>The easiest way to work with memory is the <code>MOV</code> command.It copies the value from one memory location to another. A number can also be an argument.</p>
<pre>
mov ARG1, ARG2

mov R1, 0x43
mov R1, [11]
mov R1, R2

</pre>
<p>To write a large amount of data to memory, the db command is used. With its help, we can write not only numbers, but also strings. Еhe value recording starts in the <b>POOL1</b> block.</p>
<pre>
db 'Amogus!', 0
</pre>
<p>In memory</p>

<table border='1' style='border-collapse:collapse;' cellpadding='5'><tbody>
    <tr>
        <td>№ Cell - Address</td>
        <td>Data</td>
        <td>Convert data</td>
    </tr>
    <tr>
        <td>200</td>
        <td>01000001</td>
        <td>A</td>
    </tr>
    <tr>
        <td>201</td>
        <td>01101101</td>
        <td>m</td>
    </tr>
    <tr>
        <td>202</td>
        <td>01101111</td>
        <td>o</td>
    </tr>
    <tr>
        <td>203</td>
        <td>...</td>
        <td>...</td>
    </tr>
</table>

<p>To get a special pointer, write a label at the beginning of this entry. This label will not work with <code>JMP</code>!</p>
<pre>
myText: db 'I like eat'
</pre>

<h3>Words. big digits.</h3>
<p>If you need to store and use a number that is greater than 255, then there are several ways:</p>
<b>Using the Size pointer</b>
<p>To write a large number, we simply use a size pointer</p>
<pre>
bignumber: db 1035 word
verybig: db 
mov R1, bignumber <b>word</b> # word - 2 bytes
mov verybig, 555 word
</pre>

<p>Since the addresses of the pool1 block already go beyond 8 bits, working with addresses from DB is possible only with the 'word' pointer</p>

Suddenly! Program 'Hello world'!
<pre>
Hello: db 'Hello wordl!','$'
mov INT_1, [Hello] word #INT_1 is predefined register in addres 200
int 6

</pre>
]]

page_list["math_oper.txt"] = [[
<html>
<head>
<base target=guide>
</head>
<body>
<h2>Math in gTASM</h2>
<p>The math in gTASM is not that complicated. There are basic addition <code>ADD</code> and subtraction <code>SUB</code> operations in this language.</p>
<pre>
mov R1,32 
add R1,90 # 32 + 90 = 122
sub R1,32 # 122 - 32 = 90
</pre>
<p>But do not forget that our numbers are in 8-bit cells - other commands are used to work with numbers that are greater than 255.When we try to fit a number in memory that is greater than 255, the following happens:</p>
<pre>
    mov R1, 258
             |
             V
         100000010 - binary number
    mov   00000000 - R1 cell
        ----------
      1   00000010 - R1 cell
      |
      V
 trash bucket
</pre>
<p>This rule is only for the mov command. For mathematical commands, the rules for working with numbers are different:</p>
<pre>
    add R1, 258
             |
             V
         100000010 - binary number
    add   00000000 - R1 cell
        ----------
      1   00000010 - R1 cell
      |
      V
  Carry flag - CF
</pre>
<p>That is, the marked digit now goes to CF - Carry Flag. Therefore, if we want to add up large numbers, we need several memory cells.
For example, we can use cells [1],[2] to store a 2 byte number. Let [1] be the highest byte, and [2] the lower.</p>
<pre>
    mov [1], 32
    mov [2], 123
         
              |
              V               HIGHT LOWER
MEMORY  0: 00000000  0        00100000 01111011 = 8315
        1: 00100000  32 
        2: 01111011  123
              ...             
    
</pre>
<p>For mathematical operations with such numbers, we need special commands like <code>ADC</code> and <code>SBB</code>. They are needed in order to perform operations with the highest bits.</p>
<p>The ADC command adds a Carry Flag(CF) to the sum - <code>ARG1 + ARG2 + CF</code>. SBB does a similar action - <code>ARG1 - ARG2 - CF</code></p>

<pre>
For example, we have the numbers 563 and 296 and we need to sum them up.
The first number is in [3]:[4], the second [5]:[6]
      H        L
563 = 00000010 00110011
296 = 00000001 00101000

First we need to add up the lowest bit

    add [4], [6]

        00110011
      + 00101000
        --------
      0 01011011
     CF

Next we sum up the highest bytes

    adc [3], [5]  # [3] + [5] + CF

        00000010
      + 00000001
               0 - CF
        --------
      0 00000011
     CF  
     
In total:
    563                 296                 859
    00000010 00110011 + 00000001 00101000 = 00000011 01011011
</pre>

<p>Another example. Let's sum up 200 and 100</p>
<pre>
# [0]:[1] + [2]:[3]
mov [1], 100 
mov [3], 200

add [1],[3]
adc [0],[2]

mov INT_1,1  # 1 - REGISTR mem block
mov INT_2,1  # 1 - first 5 bytes
int 11       # Cool interupt! we can see dump of memory in screen

</pre>

<h3>Size pointers</h3>
<p>If you start to have questions about the <a href='https://www.youtube.com/watch?v=DQZvseZWdfg'>type of this</a>, then do not despair. There is an easier way to add large numbers.</p>

<pre>
mov R1, 200 word # The prefix immediately sets how the number should be stored in memory
mov R2, 100 word

add R1 word, R2 word # yeah

mov INT_1,1
mov INT_2,1
int 11
</pre>

<h3>Logics operation</h3>
<p>In gTASM there are logical commands that are needed to perform logical operations. For example, take the AND command</p>
<pre>
mov R1, 15
mov R2, 6

and R1, R2

        1111 R1
    and 0110 R2
        ----
        0110 R1
</pre>
<p>There are several logical operations in the language: AND, OR, XOR, NOT. Only one argument is needed to work with NOT</p>
<pre>
mov R1,1
not R1

        00000001 1
    not 11111110 254
        
</pre>
<h3> MATH AND LOGICS - List </h3>
<dl>
  <dt>MATH</dt>
    <dd>ADD</dd>
    <dd>SUB</dd>
    <dd>ADC</dd>
    <dd>SBB</dd>
    <dd>INC - +1 in arg</dd> 
    <dd>DEC - -1 in arg</dd>
  <dt>LOGIC</dt>
    <dd>AND</dd>
    <dd>OR</dd>
    <dd>XOR</dd>
    <dd>NOT</dd>
</dl>

]]

page_list["labels.txt"] = [[
<h2>LABELS, JMP</h2>
<p>From the chapter about memory, you know that labels are needed to work with the db command.
But the main purpose of labels is to create JMP labels. These labels are needed in order to control the script.
You can use them to <i>jump</i> from one part of the script to another part.</p>
<pre>
mov R1,5
jmp 'mylabel'
add R1, 6
mylabel:

mov INT_1,1
MOV INT_2,1
int 11
# R1 = 5, not 11
</pre>
<p>With this, you can build a cycle!</p>

<pre>
Hello: db 'YOLO','$'
mov INT_1, [Hello] word

loop:
int 6
jmp 'loop'
</pre>
<h3>CALL and RET</h3>
<p>CALL and RET are needed to create routines. CALL adds the current script execution position to the stack and jumps to the label.
RET gets the address from the stack and returns back.</p>
<pre>
#predefine strings
first: db 'First String','$'
two:   db 'two string','$'

jmp 'start'

print:
    push R1 word
    mov INT_1, R1 word
    int 6
    ret

start:
mov R1, [first] word
call print
</pre>
]]


if file.IsDir( "gtasm_data", "DATA" ) == false then
    file.CreateDir("gtasm_data")
end

if file.IsDir( "gtasm", "DATA" ) == false then
    file.CreateDir("gtasm")
	MsgC(Color(0, 255, 0), "Created gtasm directory\n");
end
for filename, content in pairs( page_list ) do
    local filepath = "gtasm_data/" .. filename
    --if not file.Exists( filepath, "DATA" ) then
        file.Write( filepath, content )
    --end
end

page_list = nil 
MsgC(Color(0, 255, 0), "Created gtasm helper files");
