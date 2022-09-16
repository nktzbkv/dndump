test: dndump
	./dndump -w yay -p yay Key1 Value1 Key2 Value2
	./dndump -wj yay -pj yay Key1 Value1 Key2 Value2
	(sleep 1; ./dndump -p yay Key1 Value1 Key2 Value2) &
	./dndump -w yay
	(sleep 1; ./dndump -pj yay Key1 Value1 Key2 Value2) &
	./dndump -wj yay

dndump: dndump.m
	clang "$<" -Ofast -fobjc-arc -framework AppKit -o "$@"

install: dndump
	sudo rm -f "/usr/local/bin/$<"
	sudo cp "$<" "/usr/local/bin/$<"
