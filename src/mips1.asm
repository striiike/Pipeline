b_test_1_one:
bgtz $4, b_test_1_one_then
addu $4, $6, $7
b_test_1_two:
beq $5, $1, b_test_1_two_then
ori $0, $7, 23724
jal_test_1:
jal jal_test_1_then
ori $3, $5, -28895
end_1:

sllv $2, $1, $7
andi $0, $2, 6835
sb $2, 2366($0)
sll $2, $1, 2

b_test_1_one_then:
addu $1, $0, $7
lui $4,39476
lw $3, 100($0)
srl $1, $0, 0
multu $3, $8
mtlo $7
j b_test_1_two
xor $4, $1, $1

b_test_1_two_then:
srav $6, $4, $2
andi $6, $4, 31313
sb $4, 3770($0)
srl $5, $1, 1
divu $2, $8
mtlo $3
jal jal_test_1
addu $1, $ra, $0

jal_test_1_then:
slt $6, $7, $0
sltiu $5, $4, 1372
lh $6, 1034($0)
sll $0, $7, 1
multu $5, $8
mtlo $6
addiu $ra,$ra, 8
bgez $1, end_1
and $5, $3, $2
xori $1, $4, -23606
lb $2, 869($0)
sra $4, $4, 1
multu $3, $8
mtlo $5
jr $ra