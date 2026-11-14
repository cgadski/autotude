directory="viewer/autotude/proto"

for file in "$directory"/*; do
    if [ -f "$file" ]; then
        # -i with an explicit suffix works on both BSD and GNU sed
        sed -i.bak '1s/.*/package autotude.proto;/' "$file" && rm -f "$file.bak"
        sed -i.bak -e '/^import/ {
/protohx.Protohx/!d
}' "$file" && rm -f "$file.bak"
    fi
done
