# dndump - Apple Distributed Notifications Dumper

Subscribes to the given distributed notification and dumps data from associated user info

Clone or download, then run `make`

# Usage example

```
./dndump com.apple.iTunes.playerInfo "Player State" Artist Name
{
    Artist = "Story of the Year";
    Name = "Praying for Rain";
    "Player State" = Playing;
}
{
    Artist = Engst;
    Name = "Die H\U00f6lle hat keinen Platz mehr";
    "Player State" = Playing;
}
{
    Artist = Hurts;
    Name = Stay;
    "Player State" = Playing;
}
```
