all:compile dd clean
compile:boot.bin kernel.bin
dd:
	dd if=boot.bin of=c.img bs=512 conv=notrunc
	dd if=kernel.bin of=c.img seek=33 conv=notrunc
clean:
	rm boot.bin
	rm kernel.bin
boot.bin:boot.asm
	nasm -o boot.bin boot.asm
kernel.bin:kernel.asm
	nasm -o kernel.bin kernel.asm