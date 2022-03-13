all: test_crt.crt test_disk.d64

test_crt.crt: test_crt.bin
	bin2efcrt $< $@

test_crt.bin: test_crt.s asc2ulpet.ct
	acme -o $@ $<

asc2ulpet.ct: asc2ulpet.s
	acme -o $@ $<

test_disk.d64: test_disk.bin
	c1541 < test_disk.seq

test_disk.bin: test_disk.s
	acme -o $@ $<

clean:
	rm -f asc2ulpet.ct test_crt.bin test_crt.crt test_disk.bin test_disk.d64
