set PATH=E:\SNESASM
rename %1 "z.smc"
copy /b header.bin+z.smc zz.smc
del z.smc
asar zelda3rando.asm zz.smc
move "zz.smc" %1
echo %1%
pause