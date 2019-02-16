tema2: tema2.asm
	nasm -f elf32 -o tema2.o $<
	gcc -m32 -o tema2 tema2.o

run: tema2
	./tema2

debug: tema2
	gdb ./tema2

clean:
	rm -f tema2 tema2.o
