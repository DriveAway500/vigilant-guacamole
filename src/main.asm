%include "lib/sys.asm"

section .bss
    input_buf resb 64

section .text
    global _start

_start:
    println "=== Single Header Test ==="
    msleep 200
    
    println "Type something: "
    input input_buf, 64
    
    exit 0