all: test_crt.crt test_disk.d64

test_crt.crt: test_crt.bin
	../../tools/bin2efcrt $< $@

test_crt.bin: test_crt.s
	acme -o $@ $<

test_disk.d64: test_disk.bin
	c1541 < test_disk.seq

test_disk.bin: test_disk.s
	acme -o $@ $<

clean:
	rm -f test_crt.bin test_crt.crt test_disk.bin test_disk.d64
