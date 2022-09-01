test: dndump
	(sleep 2; ./dndump -p yay Key1 Value1 Key2 Value2) &
	./dndump -w yay

dndump: dndump.m
	clang "$<" -Ofast -framework AppKit -o "$@"

install: dndump
	sudo cp "$<" "/usr/local/bin/$<"
