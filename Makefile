.PHONY: test
test: clean
	./tests.sh

.PHONY: clean
clean:
	rm -rf tmp
