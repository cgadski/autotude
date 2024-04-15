directory="hx_src/autotude/proto"

for file in "$directory"/*; do
    if [ -f "$file" ]; then
        sed -i '1s/.*/package autotude.proto;/' "$file"
        sed -i '/^import/ { /protohx.Protohx/!d }' "$file"
    fi
done
