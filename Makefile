all: stm32p103.bin lm3s811.bin

GEN = ansi.gen.s accept.gen.s editor.gen.s quit.gen.s
LM3S811_GEN = $(GEN) lm3s811.gen.s lm3s811ram.gen.s
STM32P103_GEN = $(GEN) stm32p103.gen.s stm32p103ram.gen.s

%.bin: %.elf
	arm-none-eabi-objcopy -Obinary $< $@

%.gen.s: %.ft
	awk '{ print ".byte ", length($$0); gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); print ".ascii \"" $$0 "\""} END{print ".align 2, 0"}' < $< > $@

.s.o:
	arm-none-eabi-as -mcpu=cortex-m3 -o $@ $< 

stm32p103.o: CoreForth.s stm32p103.precomp.s $(STM32P103_GEN)

lm3s811.o: CoreForth.s lm3s811.precomp.s $(LM3S811_GEN)

lm3s811.o: lm3s811.s
	arm-none-eabi-as -mcpu=cortex-m3 -defsym USE_50MHZ=1 -o $@ $<

precomp_lm3s811.o: lm3s811.s $(LM3S811_GEN)
	arm-none-eabi-as -mcpu=cortex-m3 -defsym PRECOMP_LM3S811=1 -defsym USE_50MHZ=1 -o $@ $<

precomp_stm32p103.o: lm3s811.s $(STM32P103_GEN)
	arm-none-eabi-as -mcpu=cortex-m3 -defsym PRECOMP_STM32P103=1 -o $@ $<

stm32p103.elf: stm32p103.o
	arm-none-eabi-ld $< -o $@ -Tstm32p103.ld

lm3s811.elf: lm3s811.o
	arm-none-eabi-ld $< -o $@ -Tlm3s811.ld

precomp_lm3s811.elf: precomp_lm3s811.o
	arm-none-eabi-ld $< -o $@ -Tlm3s6965.ld

precomp_stm32p103.elf: precomp_stm32p103.o
	arm-none-eabi-ld $< -o $@ -Tlm3s6965.ld

clean:
	rm -f *.elf *.bin *.o *.gen.s

run: lm3s811.elf
	qemu-system-arm -M lm3s811evb -serial stdio -kernel lm3s811.elf -semihosting; stty sane

run_text: lm3s811.elf
	qemu-system-arm -M lm3s811evb -nographic -kernel lm3s811.elf -semihosting; stty sane

precomp: precomp_lm3s811 precomp_stm32p103

precomp_lm3s811: precomp_lm3s811.bin
	qemu-system-arm -M lm3s6965evb -nographic -kernel precomp_lm3s811.elf -semihosting > lm3s811.precomp.s; stty sane

precomp_stm32p103: precomp_stm32p103.bin
	qemu-system-arm -M lm3s6965evb -nographic -kernel precomp_stm32p103.elf -semihosting > stm32p103.precomp.s; stty sane
