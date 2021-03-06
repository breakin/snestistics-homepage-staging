---
title: User Guide
layout: default
---
Snestistics is a tool that helps the user reverse engineer games for the Super Nintendo. In general snestistics needs a ROM file (.sfc/.smc) and a custom trace file. The [second entry](tutorial-first-asm) in the tutorial series shows how to create a trace file and how to make snestistics generate assembly listing.

Snestistics is an "emulator-guided" disassembler. This helps it beat other disassemblers doing only static analysis. Because of this one (or multiple) sessions must first be "recorded" in an emulator. Each such session yields a .trace-file that represent a particular run of the game.

Command Line Reference
======================
Each feature of snestistics has a few command line options of their own. These are shown in a table in the relevant section. A typical command line invokation looks like this:
~~~~~~~~~~~~~~
snestistics -romfile myrom.sfc -autoannotate true -nmifirst 12 -nmilast 24 -asmoutfile output.asm
~~~~~~~~~~~~~~

ROM Support
===========
Almost all command requires a ROM file to be specified. Most of the time it is enough to supply the name of the ROM file and the rest should be inferred from other files (such as the trace file or by doing auto-detection based on content in the ROM-file):

{% include generated-cmd-rom.html %}

Trace
=====
A trace file describes what happened during a session in an emulator with a particular ROM-file. See the [second entry](tutorial-first-asm) in the tutorial series to see how it is created. Here is the command line options:

{% include generated-cmd-trace.html %}

Assembly Listing
================
If you supply a ROM-file and a trace-file (written by snes9x-snestistics) you can generate an assembly listing of the program. See the command line reference for relevant switches. Then annotations can be be added to beautify the assembly listing. The idea is to work with the assembler listing and the annotations in an iterative way, progressively building up an understand of the inner workings of the game.

{% include generated-cmd-asm.html %}

Annotations
===========
Snestistics uses labels-files to let the user add information about instructions. This has multiple purposes. The first is to let the user annotate and beautify the assembly listing to make it more comprehensible. The second is to guide the predict logic, the auto annotate logic as well guiding the trace log to perform better. In this section we will show some examples. It is allowed to have multiple labels-files. This can help organization of your reverse engineering effort.

Auto-annotations
----------------
In most games there are thousands of unknown pieces of code. In order to use the trace log successfully we need to give these ranges names, even if the names are anonymous and meaning less. For this there is a feature to create auto-annotations. A special labels-file is specified that will be re-generated if missing (or if *-autoannotate true*) is specified. The auto annotate feature merges ranges of code that uses branches between each other. Anything between the range where the branch happened and the range where the branch ends up is merged together. It does not follow long branches (*BRL*) or jumps, unless a hint is given (see *Labels File Format*).

{% include generated-cmd-annotation.html %}

Labels Markup
=============
## Functions
A function is composed of a range with a starting address and an end address. These are easy to find from the assembly listing. Comments can be added with ; on lines before the function keyword. The line starting with # specifies a *use comment* that is special. It is used as a summary that is written whenever someone references this function (say a jump). That way you get a summary at the site of the jump.
~~~~~~~~~~~~~~
# Important function
; This function seems very important
; It does many things
function 801000 802000 MyFunction
~~~~~~~~~~~~~~
Functions are not allowed to overlap.

## Data
Currently data ranges acts almost like a function. They are, however, allowed to be inside a function range (but not overlap function start/end).
~~~~~~~~~~~~~~
# Big table of data
; Data seems to be compressed
; TODO: needs more investigation!
data 803000 804000 Table4
~~~~~~~~~~~~~~

## Labels
Labels are similar to functions but they do not specify a range. They can be used if there is no logical range to assign to a function. They provide all the features of functions apart from that:
~~~~~~~~~~~~~~
# Important function
; This function seems very important
; It does many things
label 801000 MyFunction
~~~~~~~~~~~~~~
Labels can exist within functions and inside data blocks but they can't start at the same line as a function/data block starts/ends.

## Comments
~~~~~~~~~~~~~~
comment 801000 "Wow this really is an interesting function"
comment 801000 "I should write a book about this line!"
~~~~~~~~~~~~~~

If you want to create multi-line comments the *line* keyword is also useful:
~~~~~~~~~~~~~~
; Comment 1
; Comment 2
line 807000
~~~~~~~~~~~~~~

## Ignored lines
Lines starting with @ are ignored. They are handy when writing notes to yourself that should not be part of the assembly listing, or if you want to put some text at the top of the file for people to read:
~~~~~~~~~~~~~~
@ TODO: Re-organize the labels file
~~~~~~~~~~~~~~

## Hints

Hints is very similar to comments but they are structured. By having structured comments snestistics can read and understand them and use the information to make better choices during prediction of instruction that was not part of a trace, of relationships between functions during trace log as well as guiding auto-annotation of labels.
~~~~~~~~~~~~
hint 081234 jump_is_jsr
hint 081234 jump_is_jsr_ish
hint 081234 jsr_is_jmp
hint 081234 branch_always
hint 081234 branch_never
hint 081234 predict_jump_merge
~~~~~~~~~~~~

Hint | Description
:----|:--------------
jump_is_jsr | While the instruction is a jump (or a branch) in reality the code being called will return using RTS/RTL. The return address is prepared by the calling function in some non-standard way.
jump_is_jsr_ish | Same as *jump_is_jsr* but the return address does not have to be the instruction after the jump instruction. This is quite comment; the calling function wants to call a subroutine using *JSR* and then it want to call another part of itself. Which parts depends on some state. Instead of remembering that state (on the stack or in a register) it figures out where to go next after the *JSR* and then it can forget the state that dictate where to go next.
branch_always | This hint says that while the instruction is a branch (such as *BNE*) it will always do the jump. That is the *NE*-"test" will always succeed. This can help *predict* not trying to predict the fall-through case.
branch_never | This hint says that while the instruction is a branch (such as *BNE*) it will always fall through. That is the *NE*-"test" will always fail. This can help *predict* not trying to predict the jump case.
jsr_is_jmp | While this instruction is a *JSR* the called function will consume the return address and never return to it. The most common case here is that following the JSR there is a data table. By using *JSR* the pointer to the data table will be pushed to the stack, ready to be consumed by the function we are jumping to.
annotate_merge | When annotating code, the jump at this address should be used to merge the function we are jumping from with the function we are jumping to into one function. By default BLR and JMPs are not used to merge ranges together but this can change the default.

Code Prediction (Predict)
=========================
Not all code is executed during a typical game session. It is very typical to see that there is a branch that jumps a few instructions forward but then just after it there is some code for a cases that wasn't triggered by the emulation session. To help fill in these gaps there is the *predict* feature. It goes on a bit and see what happens if the branch hadn't been taken etc. It sometimes become confused and need some help using hints, but in general it is very useful to get a cleaner source code; it makes it very easy to spot data inside a function.

Currently this affects the assembly listing and the auto-annotation feature. The latter is because when more code is available more and larger functions can be identified.

NOTE: By default prediction only works within annotated functions.

{% include generated-cmd-predict.html %}

Scripting
=========
Some features of snestistics can only be reached from scripts. Currently snestistics only supports scripts written in the scripting language squirrel. See *Trace log* and *Rewind* for how to enable scripts there. See the *Scripting Reference* to find out what functions the different objects supports.

{% include generated-cmd-scripting.html %}

Trace Log
=========
The trace log shows what functions are being called. A NMI (basically a frame) range can be supplied to limit the log. This feature support adding in a script to enhance the log.

{% include generated-cmd-tracelog.html %}

When the trace log feature is enabled on the command line and a script is given snestistics expects the script to be a squirrel script with the following functions:

~~~~~~
trace_log_init(replay)
    Replay replay: a replay object
    returns: nothing
~~~~~~
This function is used for setup. Breakpoints can be set on the replay objects and global squirrel state can be constructed if the user wants that.

~~~~~~
trace_log_parameter_printer(replay, report)
    Replay replay: a replay object
    ReportWriter report: a report writer object
    returns: nothing
~~~~~~
This function is called whenever the trace log hits a program counter that it has a breakpoint set for. The trace log system itself will print the name of the function and determine indentation, but this is a chance to do additional printing on some functions that are under investigation.

Rewind
======
This feature allow generation of a visual report depicting the flow of data through the processor. This can sometimes be very helpful to track where values to a function is coming from. This feature **requires scripting** in order to run.

NOTE: This feature is currently in re-development since it does not understand DMA (or writing to) $2180. It also needs scripting support to be controllable on the command line.

{% include generated-cmd-rewind.html %}

Scripting Reference
===================

Currently only two objects exists that the script can interact with. We expect this to increase in the future as more parts of snestistics is exposed to scripting.

Replay
------
These are the operations that can be performed on an instance of the Replay class.

~~~~~~
replay.set_breakpoint(pc)
    integer pc: the program counter to set a break point at
    returns: nothing

replay.set_breakpoint_range(pc_start, pc_end)
    integer pc_start: the first program counter to set a break point at
    integer pc_end: the last program counter to set a break point at
    returns: nothing

replay.read_byte(address)
    integer address: 24-bit address specifying where to read a byte (8-bit)
    returns: integer

replay.read_word(address)
    integer address: 24-bit address specifying where to read a byte (16-bit)
    returns: integer

replay.read_long(address)
    integer address: 24-bit address specifying where to read a byte (24-bit)
    returns: integer

replay.pc()
    returns: current program counter

replay.a()
    returns: current value of register a (16-bit)

replay.al()
    returns: current low byte of register a (8-bit)

replay.ah()
    returns: current high byte of register a (8-bit)

replay.x()
    returns: current value of register x (16-bit)

replay.xl()
    returns: current low byte of register x (8-bit)

replay.xh()
    returns: current high byte of register x (8-bit)

replay.y()
    returns: current value of register y (16-bit)

replay.yl()
    returns: current low byte of register y (8-bit)

replay.yh()
    returns: current high byte of register y (8-bit)

replay.p()
    returns: current value of status register (16-bit)

replay.s()
    returns: current value of stack register (16-bit)

replay.dp()
    returns: current value of direct page register (16-bit)

replay.db()
    returns: current value of data bank register (8-bit)
~~~~~~

ReportWriter
------------
These are the operations that can be performed on an instance of the ReportWriter class:

~~~~~~
report_writer.print(str)
    str: string to write in the report
    returns: nothing
~~~~~~

Will write the string str to the report at the current indentation level. Adds a newline automatically.
