# rust stuff

This directory has the indexers/dumpers that I use to extract data from replay files. There's a small library (`src/`) that walks through a protobuf replay and a simple baseline class `IndexingListener` that keeps track of some essential things like the mapping from in-game players "IDs" to database keys. (Over the course of a game, two different players can occupy the same altitude player id.)
