test: dndump
	./dndump com.apple.iTunes.playerInfo "Player State" Artist Name

dndump: dndump.m
	clang "$<" -Ofast -framework AppKit -o "$@"

install: dndump
	sudo cp "$<" "/usr/local/bin/$<"
