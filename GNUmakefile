test: dndump
	(sleep 1; ./dndump -p yay Key1 Value1 Key2 Value2) &
	./dndump -w yay
	(sleep 1; ./dndump -pj yay Key1 Value1 Key2 Value2) &
	./dndump -wj yay

dndump: dndump.m
	clang "$<" -Ofast -framework AppKit -o "$@"

install: dndump
	sudo cp "$<" "/usr/local/bin/$<"
