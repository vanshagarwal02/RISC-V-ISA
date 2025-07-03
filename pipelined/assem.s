sub x4, x3, x2
add x1, x2, x3
add x6, x2, x3 
add x7, x6, x1
add x7, x7, x7
add x7, x7, x7
beq x2, x2, 5
sd x7, 0(x6)
ld x8, 0(x6)
add x9, x6, x7
sd x9, 0(x7)
ld x11, 0(x7)
sd x11, 8(x2)
ld x12, 8(x2)
and x21, x2, x3
or x22, x2, x3
