# Pipeline CPU

Pipeline CPU consists of F_PC, IM, D_REG, D_NPC, D_EXT, D_GRF,  D_CMP, E_REG, E_ALU, M_REG, M_DM, W_REG, u_CTRL, mips.

***适用范围***：BUAA_CO p5, p6, p7, p8.

## First Things First

An overview of the whole CPU `p5-version`

![p5map](C:\Users\25989\Desktop\h1ccup\BUAA_CO\files\P5\design\p5map.png)

## Containing Parts

### MIPS ###

This module is intended to be **Top Module**.

具体包括了各个模块的实例化，MUX的应用和布线的连接。不如直接看代码。

###### Code

```verilog

```



### PC ###

This module is intended to be load current instrument address, which is why called **Program Counter**.

***

#### Definition of ports

| Port | Input/Output | Width | Description  |
| ---- | ------------ | ----- | ------------ |
| PC   | I            | 32    | Previous one |
| CLK  | I            | 1     | Clock        |
| RST  | I            | 1     | Reset        |
| PC'  | O            | 32    | Next one     |

****

### NPC ###

This module is motivated by **PC**, to load the next instrument address to **PC**, which is used to motivate **IM**.

得到下一条指令，可能的来源有PC，`j` type 指令的的instr_index，和`jr`指令的寄存器

***

#### Definition of ports

| Port    | Input/Output | Width | Description           |
| :------ | ------------ | ----- | --------------------- |
| PC      | I            | 32    | Previous one          |
| PCSrc   | I            | 1     | Represent Branching   |
| SignImm | I            | 32    | Sign_extend Immediate |
| PCJump  | I            | 32    | Used for `j`and `jal` |
| RD1     | I            | 32    | Used for `jr`         |
| NPC     | O            | 32    | Next on               |

### IM 

This module is motivated by **PC**.

用于通过pc读取指令

#### Definition of ports

| Port    | Input/Output | Width | Description     |
| :------ | ------------ | ----- | --------------- |
| PC      | I            | 32    | Program Counter |
| CLK     | I            | 1     | Clock           |
| RST     | I            | 1     | Reset           |
| SignImm | O            | 32    | sign_ext Imm    |

## F section

### F_IFU

整合了**F_PC**和**IM**两个指令块，效果相同

Add **en** port, used to stall the CPU, when unavoidable hazard happens.

#### Definition of ports

| Port  | Input/Output | Width | Description                    |
| :---- | ------------ | ----- | ------------------------------ |
| en    | I            | 1     | Enable port                    |
| npc   | I            | 32    | Program Counter                |
| clk   | I            | 1     | Clock                          |
| rst   | I            | 1     | Reset                          |
| pc    | O            | 32    | Last instr's pc, used for test |
| instr | O            | 32    | The instr to fetch             |

****

## D section

### D_REG

流水上一级指令及其结果至下一级。

Inherit last section' s instruction and results.

#### Definition of ports

| Port    | Input/Output | Width | Description |
| :------ | ------------ | ----- | ----------- |
| clk     | I            | 1     | Clock       |
| reset   | I            | 1     | Reset       |
| clr     | I            | 1     | Clear reg   |
| en      | I            | 1     | Enable port |
| F_instr | I            | 32    |             |
| F_pc    | I            | 32    |             |
| D_instr | O            | 32    |             |
| D_pc    | O            | 32    |             |
| D_pc8   | O            | 32    |             |

****

### D_NPC ###

This module is motivated by **PC**, to load the next instrument address to **PC**, which is used to motivate **IM**.

得到下一条指令，可能的来源有PC，`j` type 指令的的instr_index，和`jr`指令的寄存器

***

#### Definition of ports

| Port    | Input/Output | Width | Description           |
| :------ | ------------ | ----- | --------------------- |
| PC      | I            | 32    | Previous one          |
| PCSrc   | I            | 1     | Represent Branching   |
| SignImm | I            | 32    | Sign_extend Immediate |
| PCJump  | I            | 32    | Used for `j`and `jal` |
| RD1     | I            | 32    | Used for `jr`         |
| NPC     | O            | 32    | Next on               |

### D_GRF

General Register File, used for fast computation.

通用寄存器堆，用于快速执行指令。

Enable it to have forwarding fuction from W->D.

```verilog
assign RD1 = (A1 == A3 && A3 != 5'b0 && WE) ? WD3 : grf[A1];
assign RD2 = (A2 == A3 && A3 != 5'b0 && WE) ? WD3 : grf[A2];
```

#### Definition of ports

| Port | Input/Output | Width | Description     |
| :--- | ------------ | ----- | --------------- |
| pc   | I            | 32    | Program Counter |
| clk  | I            | 1     | Clock           |
| rst  | I            | 1     | Reset           |
| A1   | I            | 5     | Address of RD1  |
| A2   | I            | 5     | Address of RD2  |
| A3   | I            | 5     | Address of WD3  |
| WE   | I            | 1     | Write eble      |
| WD3  | I            | 32    | Data to Write   |
| RD1  | O            | 32    | Read data       |
| RD2  | O            | 32    | Read data       |


***

### D_EXT

It can extend in zero or sign, and output the result of `lui`.

#### Definition of ports

| Port     | Input/Output | Width | Description |
| :------- | ------------ | ----- | ----------- |
| D_EXTIn  | I            | 16    | In          |
| D_EXTOp  | I            | 2     | Op          |
| D_EXTOut | O            | 32    | Result      |


***

### D_CMP

This module is used to have the result of `beq` or `branch` type.

#### Definition of ports

| Port | Input/Output | Width | Description |
| :--- | ------------ | ----- | ----------- |
| cmp1 | I            | 32    | In          |
| cmp2 | I            | 32    | In          |
| isBr | O            | 1     | Is Branch?  |


***

## E section

### E_REG

流水上一级指令及其结果至下一级。

Inherit last section' s instruction and results.

#### Definition of ports

| Port    | Input/Output | Width | Description |
| :------ | ------------ | ----- | ----------- |
| clk     | I            | 1     | Clock       |
| reset   | I            | 1     | Reset       |
| clr     | I            | 1     | Clear reg   |
| en      | I            | 1     | Enable port |
| D_instr | I            | 32    |             |
| D_pc    | I            | 32    |             |
| D_pc8   | I            | 32    |             |
| D_ext   | I            | 32    |             |
| D_RD1   | I            | 32    |             |
| D_RD2   | I            | 32    |             |
| E_instr | O            | 32    |             |
| E_pc    | O            | 32    |             |
| E_pc8   | O            | 32    |             |
| E_ext   | O            | 32    |             |
| E_RD1   | O            | 32    |             |
| E_RD2   | O            | 32    |             |

****

### E_ALU

算术逻辑单元，提供 32 位按位与、按位或、加法、减法、判断相等和其他的功能。

#### Definition of ports

| Port   | Input/Output | Width | Description                           |
| ------ | ------------ | ----- | ------------------------------------- |
| A      | I            | 32    | 参与 ALU 计算的第一个值。             |
| B      | I            | 32    | 参与 ALU 计算的第二个值。             |
| ALUOp  | I            | 4     | ALU 功能的选择信号，具体见功能定义。  |
| shamt  | I            | 5     | shift                                 |
| Result | O            | 32    | ALU 的计算结果。                      |
| isZero | O            | 1     | 当 A = B 时为 1，否则为 0。// useless |

#### Definition of Function

| 序号 | 功能名称   | 功能描述                |
| ---- | ---------- | ----------------------- |
| 0000 | A and B    |                         |
| 0001 | A or B     |                         |
| 0010 | A + B      |                         |
| 0100 | A and ~B   |                         |
| 0101 | A or ~B    |                         |
| 0110 | A - B      |                         |
| 0111 | SLT        | (A <= B) boolean value  |
| 1000 | B          | Used for `lui` function |
| 1010 | B << shamt | Used for `sll` function |
|      |            |                         |


***

### CTRL

Control Unit. Try checking the reference. I am going to utilize it many times, it might be a little waste of resources, but who cares ?

#### Definition of Ports

| Ports      | Input/Output | Width |
| ---------- | ------------ | ----- |
| instr      | I            | 32    |
| stage      | I            | 2     |
| D_sel_EXT  | O            | 2     |
| D_sel_NPC  | O            | 2     |
| D_sel_CMP  | O            | 2     |
| D_Tuse_rs  | O            | 32    |
| D_Tuse_rt  | O            | 32    |
| E_sel_ALU  | O            | 4     |
| E_fsel     | O            | 1     |
| E_sel_srcB | O            | 1     |
| E_Addr     | O            | 5     |
| E_Tnew     | O            | 32    |
| E_SAddr    | O            | 5     |
| M_fsel     | O            | 2     |
| M_Addr     | O            | 5     |
| M_Tnew     | O            | 32    |
| M_SAddr    | O            | 5     |
| M_en_DM    | O            | 2     |
| W_fsel     | O            | 2     |
| W_sel_A3   | O            | 2     |
| W_en_GRF   | O            | 1     |
| W_Addr     | O            | 5     |
| W_Tnew     | O            | 32    |

## M section

### M_REG

流水上一级指令及其结果至下一级。

Inherit last section' s instruction and results.

#### Definition of ports

| Port    | Input/Output | Width | Description |
| :------ | ------------ | ----- | ----------- |
| clk     | I            | 1     | Clock       |
| reset   | I            | 1     | Reset       |
| clr     | I            | 1     | Clear reg   |
| en      | I            | 1     | Enable port |
| E_instr | I            | 32    |             |
| E_pc    | I            | 32    |             |
| E_pc8   | I            | 32    |             |
| E_ext   | I            | 32    |             |
| E_RD1   | I            | 32    |             |
| E_RD2   | I            | 32    |             |
| E_alu   | I            | 32    |             |
| M_instr | O            | 32    |             |
| M_pc    | O            | 32    |             |
| M_pc8   | O            | 32    |             |
| M_ext   | O            | 32    |             |
| M_RD1   | O            | 32    |             |
| M_RD2   | O            | 32    |             |
| M_alu   | O            | 32    |             |

### M_DM

#### Definition of ports

| Port | Input/Output | Width | Description              |
| :--- | ------------ | ----- | ------------------------ |
| pc   | I            | 32    | Program Counter          |
| clk  | I            | 1     | Clock                    |
| rst  | I            | 1     | Reset                    |
| WE   | I            | 1     | Write Eble               |
| A    | I            | 32    | Address to read or Write |
| WD   | I            | 32    | Data to Write            |
| RD   | O            | 32    | Data to read             |



## CP0

#### Introduction

协处理器 0，包含 4 个 32 位寄存器，用于支持中断和异常。

#### Definition of ports

| 端口      | 输入/输出 | 位宽 | 描述                                               |
| --------- | --------- | ---- | -------------------------------------------------- |
| A1        | I         | 5    | 指定 4 个寄存器中的一个，将其存储的数据读出到 RD。 |
| A2        | I         | 5    | 指定 4 个寄存器中的一个，作为写入的目标寄存器。    |
| WD        | I         | 32   | 写入寄存器的数据信号。                             |
| VPC       | I         | 32   | 目前传入的下一个 EPC 值。                          |
| ExcCodeIn | I         | 5    | 目前传入的下一个 ExcCode 值。                      |
| BDIn      | I         | 32   | 目前传入的下一个 BD 值。                           |
| HWInt     | I         | 6    | 外部硬件中断信号。                                 |
| en        | I         | 1    | 写使能信号，高电平有效。                           |
| eret      | I         | 1    | eret 指令信号，高电平有效。                        |
| clk       | I         | 1    | 时钟信号。                                         |
| reset     | I         | 1    | 同步复位信号。                                     |
| IntReq    | O         | 1    | 输出当前的中断请求。                               |
| RD        | O         | 32   | 输出 A 指定的寄存器中的数据。                      |

|      |      |      |
| ---- | ---- | ---- |
|      |      |      |
|      |      |      |
|      |      |      |
|      |      |      |

## W section

### W_REG

流水上一级指令及其结果至下一级。

Inherit last section' s instruction and results.

#### Definition of ports

| Port    | Input/Output | Width | Description |
| :------ | ------------ | ----- | ----------- |
| clk     | I            | 1     | Clock       |
| reset   | I            | 1     | Reset       |
| clr     | I            | 1     | Clear reg   |
| en      | I            | 1     | Enable port |
| M_instr | I            | 32    |             |
| M_pc    | I            | 32    |             |
| M_pc8   | I            | 32    |             |
| M_alu   | I            | 32    |             |
| M_RD    | I            | 32    |             |
| W_instr | O            | 32    |             |
| W_pc    | O            | 32    |             |
| W_pc8   | O            | 32    |             |
| W_alu   | O            | 32    |             |
| W_RD    | O            | 32    |             |



### 





## Forwarding Unit

### The result can be forwarded

```verilog
assign E_out = (E_fsel) ? E_ext : E_pc8;
```

```verilog
assign M_out = (M_fsel) ? M_pc8 : M_alu;
```

```verilog
assign W_out = (W_fsel == `w_alu) ? W_alu : (W_fsel == `w_pc8) ? W_pc8 : W_RD;
```

### HMUX needs forward result

```verilog
assign HMUX_RD1 = (D_rs == E_Addr && E_Addr != 5'b0) ? E_out : (D_rs == M_Addr && M_Addr != 5'b0) ? M_out : D_RD1;
assign HMUX_RD2 = (D_rt == E_Addr && E_Addr != 5'b0) ? E_out : (D_rt == M_Addr && M_Addr != 5'b0) ? M_out : D_RD2;
```

```verilog
assign HMUX_srcA = (E_rs == M_Addr && M_Addr != 5'b0) ? M_out : (E_rs == W_Addr && W_Addr != 5'b0) ? W_out : E_RD1;
assign HMUX_srcB = (E_rt == M_Addr && M_Addr != 5'b0) ? M_out : (E_rt == W_Addr && W_Addr != 5'b0) ? W_out : E_RD2;
```

```verilog
assign HMUX_WD = (M_rt == W_Addr && W_Addr != 5'b0) ? W_out : M_RD2;
```

## Stall Unit

Stall only happens on D section by clearing E_REG and FREEZE F_PC and D_REG.

```verilog
// stall
assign D_stall_rs_E = (E_SAddr != 5'b0 && D_rs == E_SAddr) && (E_Tnew > D_Tuse_rs);
assign D_stall_rs_M = (M_SAddr != 5'b0 && D_rs == M_SAddr) && (M_Tnew > D_Tuse_rs);

assign D_stall_rs   = D_stall_rs_E | D_stall_rs_M;

assign D_stall_rt_E = (E_SAddr != 5'b0 && D_rt == E_SAddr) && (E_Tnew > D_Tuse_rt);
assign D_stall_rt_M = (M_SAddr != 5'b0 && D_rt == M_SAddr) && (M_Tnew > D_Tuse_rt);

assign D_stall_rt   = D_stall_rt_E | D_stall_rt_M;
assign D_stall      = D_stall_rs | D_stall_rt;
```

​	

## Instruction Classification

- **cal_r**: add, sub, and, or, nor, xor, slt, sltu
- **cal_i**: addi, andi, ori, xori, slti, sltiu
- **shift**: sll, sra, srl
- **shiftv**: sllv, srav, srlv
- **load**: lw, lh, lb
- **store**: sw, sh, sb
- **branch**：beq, bne
- **J类**：jal, j
- **特殊**：jr, lui
- **中断异常**: eret mfc0 mtc0 syscall



## Tnew & Tuse

### Tuse Table

| Instr Type | Tuse_rs | Tuse_rt |
| ---------- | ------- | ------- |
| cal_r      | 1       | 1       |
| cal_i      | 1       | INF     |
| shift      | INF     | 1       |
| shiftv     | 1       | 1       |
| load       | 1       | INF     |
| store      | 1       | 2       |
| branch     | 0       | 0       |
| jump       | INF     | INF     |
| jr         | 0       | INF     |



 ### Tnew Table

| Instr Type | Tnew_E | Tnew_M | Tnew_W |
| ---------- | ------ | ------ | ------ |
| cal_r      | 1      | 0      | 0      |
| cal_i      | 1      | 0      | 0      |
| shift      | 1      | 0      | 0      |
| shiftv     | 1      | 0      | 0      |
| load       | 2      | 1      | 0      |
| store      | X(0)   | X(0)   | X(0)   |
| branch     | X(0)   | X(0)   | X(0)   |
| jal        | 0      | 0      | 0      |
| jr         | X(0)   | X(0)   | X(0)   |
| lui        | 0      | 0      | 0      |



## 思考题p5

1. (无转发) (充分的转发) (仅ALU至ALU的转发) 分别对应 (300ps) (400ps) (360ps)

   无转发：(7 + 2) × 300 = 2700ps，充分的转发：7 × 400ps = 2800ps，加速比：2700/2800 = 0.96

   from xlm 老师ppt

   不过这道应该想问的是无脑转发的情况下一些数据是不能马上转发的，例如lwso指令，需要等待M级才能转发，而且还不对，不过稍稍改下转发方法就好啦

2. 因为相当于存入的指令是下两条的指令所以+8

3. 关键路径过长

4. 本质是W级向D级的转发，具体实现参考上文D_GRF module

5. E, M, W三级，转发数据通路可以参考上文`The result can be forwarded`和`HMUX needs forward result`两个部分

6. 比如说向下一级流水更多上一级的结果，比如ext之类的，还有需要在例如D_CMP，u_CTRL中增加更多的分支选项

7. 我使用的是分布式译码器，但是写在了同一个ctrl unit里面，优势就是好写，不足就是有点浪费



## 思考题p6

1. 需要模拟乘除的延迟，需要寄存器来保存hi lo值，否则只能使用一周期

2. 首先CPU会初始化三个通用寄存器用来存放被乘数，乘数，部分积的二进制数，部分积寄存器初始化为0。然后在判断乘数寄存器的低位是低电平还是高电平（0/1）如果为0则将乘数寄存器右移一位，同时将部分积寄存器也右移一位，在位移时遵循计算机位移规则，乘数寄存器低位溢出的一位丢弃，部分积寄存器低位溢出的一位填充到乘数寄存器的高位，同时部分积寄存器高位补0。如果为1则将部分积寄存器加上被乘数寄存器，在进移位操作。当所有乘数位处理完成后部分积寄存器做高位乘数寄存器做低位就是最终乘法结果。  除法原理与此类似，都是利用位移运算模拟列竖式的过程，利用三个通用寄存器将商和余数计算出来，也放在了ALU中统一执行。

3. 当busy或start信号产生的时候，阻塞mfhi，mflo, mthi, mtlo，不阻塞mult等指令因为可以覆盖

   ```verilog
   assign D_stall_mdu  = (busy || start) && D_instr_mdu;
   assign D_stall      = D_stall_rs | D_stall_rt | D_stall_mdu;
   ```

   

4. 清晰性可以一下看出要保留一个字的哪些字节，可以适用于所有的存储指令

5. 实际上是一个字,当我们只需要对字节或半字访问时，按字节访问内存性能更由优势。如果此时还采用按字访问，则需要首先将整个字从内存中拿出来，然后再从字中寻找，效率会更低。因此再sb，sh或lb，lh的情况下，按字节读写效率都会高于按字读写。

6. 指令分类

   

   ```verilog
   	wire load, store, branch, cal_r, cal_i, mc, mt, mf;
   
       assign cal_r = add | sub | slt | sltu |
                       sll | 
                       And | Or; 
   
       assign cal_i = addi | andi | ori;                 
   
       assign load   = lw | lh | lb;
       assign store  = sw | sh | sb;
       assign branch = beq | bne;
   
   
       assign D_instr_mdu = mc | mt | mf;
   
       assign mc = mult | multu | div | divu;
       assign mt = mtlo | mthi;
       assign mf = mflo | mfhi;
   ```

   

7. 不同的指令冲突是乘除，例如`mfhi` `mflo` `mult`的转发，解决方式就是加上转发和乘除指令之间的阻塞 测试样例片段

   ```assembly
    mfhi  $t5
    mflo  $t5
    lb    $t6, 0x7a6a($t7)
    lw    $t7, 0xd($t6)
    ori   $t6, $t7, 0x5044
    divu  $zero, $t7, $t6
    mfhi  $t6
    mflo  $t6
    lw    $zero, 4($zero)
    lh    $zero, 0x2c($zero)
    andi  $zero, $s0, 0xd
    mthi  $zero
    mfhi  $s0
    mflo  $s0
    mtlo  $t3
    mfhi  $t3
    mflo  $t3
    lb    $t5, 0xe96($t4)
    lw    $t4, 0x21($t5)
    nop   
    mult  $t4, $t5
    mfhi  $t4
    mflo  $t4
    lw    $zero, 8($zero)
    lh    $zero, 0x38($zero)
    nop   
    multu $t6, $zero
    mfhi  $t6
    mflo  $t6
   ```

8. 随机生成的测试，不足之处在于有概率遗漏测试，优势在于方便，容易大量生成测试数据。特殊解决方案，在随机生成的时候让rs,rt,rd寄存器在3~6和31寄存器内随机生成，大大缩小其范围，增加了数据冒险生成的可能性，也就降低了数据通路测试遗漏的可能性。

   

## 思考题P7

1. 鼠标和键盘产生中断信号，进入中断处理区的对应位置，将输入信号从鼠标和键盘中读入寄存器。
2. 如果用户地址不同则在不同的cpu上会产生不一样的后果，例如访问了DM，timer，但是如果仅限制在指令区域，是可以的。
3. 是与外设进行沟通的模块，所有有关地址的操作和外设的信号均通过系统桥处理，cpu也看不懂你在干嘛，方便操作和修改
4. ![568e1857398f44724334adfc5819082](C:\Users\25989\AppData\Local\Temp\WeChat Files\568e1857398f44724334adfc5819082.jpg)
5. 如果本身就是nop那么不需要处理， 如果是阻塞产生的空泡则需要保留被阻塞指令的pc和bd信号，倘若不保留就会产生错误的VPC，毕竟阻塞也代表正在执行这条指令
6. 在不考虑异常处理的时候是可以的，考虑则不行，原因在于`jalr`后的两个寄存器相同，如果延迟槽指令相同VPC将存入PC-4 再次执行`jalr`则会有可能跳到错误的地址



#### Reference

```verilog

`define op_r 6'b000000
`define op_beq 6'b000100
`define op_j 6'b000010
`define op_jal 6'b000011
`define op_lui 6'b001111
`define op_lw 6'b100011
`define op_ori 6'b001101
`define op_sw 6'b101011
`define op_sb 6'b101000
`define op_lb 6'b100000

`define f_add 6'b100000
`define f_sub 6'b100010
`define f_and 6'b100100
`define f_jalr 6'b001001
`define f_jr 6'b001000
`define f_or 6'b100101
`define f_sll 6'b000000
`define f_sllv 6'b000100
`define f_slt 6'b101010


// RegDst
`define grf_rt 2'b00
`define grf_rd 2'b01
`define grf_ra 2'b10

// Branch
`define npc_offset 2'b00
`define npc_index 2'b01
`define npc_ra 2'b10

// memtoreg
`define wd3_alu 2'b01
`define wd3_rd 2'b00
`define wd3_pc 2'b10

// ALUSrc
`define alu_rd2 2'b00
`define alu_imm 2'b01

// ALUControl
`define AND 4'b0000
`define OR 4'b0001
`define ADD 4'b0010
`define SUB 4'b0110
`define SLT 4'b0111
`define LUI 4'b1000
`define SLL 4'b1010

`define e_fsel_pc8 2'b01
`define e_fsel_ext 2'b00


`define m_fsel_pc8 2'b01
`define m_fsel_alu 2'b00

`define inf 100
```

