#!/usr/bin/env bash
# nbp_viewer.sh — interactive viewer for nbp_CAAC / nbp_CAAV arrays
# Usage: nbp_viewer.sh [box_w] [box_h] [caac_file] [caav_file]

# ── Configuration ────────────────────────────────────────────────────────────
BOX_W="${1:-20}"
BOX_H="${2:-20}"
CAAC_FILE="${3:-nbp_CAAC.array}"
CAAV_FILE="${4:-nbp_CAAV.array}"

MISSING_CHAR="·"

# ── Load arrays ──────────────────────────────────────────────────────────────
if [[ ! -f "$CAAC_FILE" || ! -f "$CAAV_FILE" ]]; then
    echo "Error: cannot find array files '$CAAC_FILE' and/or '$CAAV_FILE'" >&2
    echo "Usage: $0 [box_w] [box_h] [caac_file] [caav_file]" >&2
    exit 1
fi

source "$CAAC_FILE"
source "$CAAV_FILE"

# ── Determine array bounds dynamically ───────────────────────────────────────
arr_min_x=99999; arr_max_x=-99999
arr_min_y=99999; arr_max_y=-99999

for key in "${!nbp_CAAV[@]}"; do
    x="${key%%,*}"
    y="${key##*,}"
    (( x < arr_min_x )) && arr_min_x=$x
    (( x > arr_max_x )) && arr_max_x=$x
    (( y < arr_min_y )) && arr_min_y=$y
    (( y > arr_max_y )) && arr_max_y=$y
done

# ── Build font index from system fontconfig at startup ────────────────────────
# Returns a JSON-style lookup used by char_info below.
# fc-list enumerates all installed fonts with their Unicode charset coverage.
# We parse each font's charset ranges at startup (~80ms) so per-keypress
# lookup is a fast in-process operation with no subprocess overhead.
# Font index written to a temp file at startup to avoid shell-quoting issues
# when passing large JSON blobs into python3 subprocesses later.
_FONT_INDEX_FILE=$(mktemp /tmp/nbp_fontindex_XXXXXX.json)

# Detect the system's preferred monospace font — this is what most terminal
# emulators resolve to, so we prioritise it in the font lookup order.
_TERMINAL_FONT=$(fc-match monospace --format='%{family}' 2>/dev/null \
    | cut -d, -f1 | tr '[:upper:]' '[:lower:]')

if command -v fc-list &>/dev/null; then
    fc-list --format='%{family}:%{charset}\n' 2>/dev/null | \
    python3 -c "
import sys, json

terminal_font = sys.argv[1].lower()

def parse_charset(cs):
    ranges = []
    for token in cs.split():
        if not token: continue
        if '-' in token:
            try:
                a, b = token.split('-', 1)
                ranges.append([int(a,16), int(b,16)])
            except: pass
        else:
            try:
                v = int(token, 16)
                ranges.append([v, v])
            except: pass
    return ranges

font_ranges = []
seen = set()
for line in sys.stdin:
    line = line.strip()
    if ':' not in line: continue
    parts = line.split(':', 1)
    name = parts[0].split(',')[0].strip()
    if name in seen: continue
    seen.add(name)
    charset = parts[1].strip() if len(parts) > 1 else ''
    if charset:
        font_ranges.append([name, parse_charset(charset)])

# Sort: terminal font first, then other mono fonts, then the rest
def priority(entry):
    n = entry[0].lower()
    if n == terminal_font:      return 0
    if 'mono' in n:             return 1
    return                             2

font_ranges.sort(key=priority)
print(json.dumps(font_ranges))
" "$_TERMINAL_FONT" 2>/dev/null > "$_FONT_INDEX_FILE"
else
    echo '[]' > "$_FONT_INDEX_FILE"
fi

# ── Terminal / ANSI helpers ───────────────────────────────────────────────────
ESC=$'\x1b'
tput_lines=$(tput lines)
tput_cols=$(tput cols)

cursor_hide()  { printf '%s[?25l' "$ESC"; }
cursor_show()  { printf '%s[?25h' "$ESC"; }
clear_screen() { printf '%s[2J'   "$ESC"; }
move_to()      { printf '%s[%d;%dH' "$ESC" "$1" "$2"; }
clear_eol()    { printf '%s[K'    "$ESC"; }

# Colours
C_RESET=$'\x1b[0m'
C_BORDER=$'\x1b[38;5;240m'
C_MISSING=$'\x1b[38;5;88m'
C_CURSOR_BG=$'\x1b[48;5;160m'
C_LABEL=$'\x1b[38;5;244m'
C_VALUE=$'\x1b[38;5;255m'
C_BITS_0=$'\x1b[38;5;240m'
C_BITS_1=$'\x1b[38;5;214m'
C_COORD=$'\x1b[38;5;75m'
C_CHAR=$'\x1b[38;5;213m'
C_PIXEL_ON=$'\x1b[48;5;46m'    # bright green filled pixel
C_PIXEL_OFF=$'\x1b[48;5;232m'  # near-black empty pixel

# ── State ─────────────────────────────────────────────────────────────────────
vp_x=$arr_min_x
vp_y=$arr_min_y
cx=0
cy=0

# ── Layout ───────────────────────────────────────────────────────────────────
cell_w=1
inner_w=$(( BOX_W * cell_w ))
inner_h=$BOX_H
total_w=$(( inner_w + 2 ))
total_h=$(( inner_h + 2 ))

box_row=1
box_col=2

# Exploded view sits to the right of the box, with a 2-col gap
# Each pixel cell in the exploded view is PIXEL_W cols × PIXEL_H rows
PIXEL_W=3
PIXEL_H=2
# Glyph is 2 cols × 4 rows of pixels → exploded = 6 cols × 8 rows
# Plus a 1-char border each side → 8 cols × 10 rows total
exp_inner_w=$(( 2 * PIXEL_W ))
exp_inner_h=$(( 4 * PIXEL_H ))
exp_total_w=$(( exp_inner_w + 2 ))
exp_total_h=$(( exp_inner_h + 2 ))
exp_col=$(( box_col + total_w + 2 ))
exp_row=$box_row

# Status rows below the box (with blank lines between)
status_row=$(( box_row + total_h + 1 ))
status_bits_row=$(( status_row + 2 ))
status_hint_row=$(( status_row + 4 ))

# ── Helper: decimal → 8-bit binary string with coloured digits ───────────────
to_binary_coloured() {
    local val=$1
    local bits=""
    for (( b=7; b>=0; b-- )); do
        if (( (val >> b) & 1 )); then
            bits+="${C_BITS_1}1${C_RESET}"
        else
            bits+="${C_BITS_0}0${C_RESET}"
        fi
    done
    echo "$bits"
}

# ── Helper: derive codepoint and font name using system font index ────────────
char_info() {
    local char="$1"
    python3 -c "
import sys, json

index_file = sys.argv[1]
char = sys.argv[2]

try:
    with open(index_file) as f:
        font_ranges = json.load(f)
except Exception:
    font_ranges = []

if not char:
    print('? [unknown]')
    sys.exit(0)

v = ord(char)
cp = f'U+{v:04X}' if v < 0x10000 else f'U+{v:05X}'

font = 'unknown'
for name, ranges in font_ranges:
    for a, b in ranges:
        if a <= v <= b:
            font = name
            break
    if font != 'unknown':
        break

print(f'{cp} [{font}]')
" "$_FONT_INDEX_FILE" "$char" 2>/dev/null || echo "?"
}

# ── Draw the main viewport border ─────────────────────────────────────────────
draw_border() {
    local r=$box_row c=$box_col

    move_to $r $c
    printf '%s┌' "$C_BORDER"
    printf '─%.0s' $(seq 1 $inner_w)
    printf '┐%s' "$C_RESET"

    local row
    for (( row=1; row<=inner_h; row++ )); do
        move_to $(( r + row )) $c
        printf '%s│%s' "$C_BORDER" "$C_RESET"
        move_to $(( r + row )) $(( c + inner_w + 1 ))
        printf '%s│%s' "$C_BORDER" "$C_RESET"
    done

    move_to $(( r + inner_h + 1 )) $c
    printf '%s└' "$C_BORDER"
    printf '─%.0s' $(seq 1 $inner_w)
    printf '┘%s' "$C_RESET"
}

# ── Draw the exploded view border ─────────────────────────────────────────────
draw_exp_border() {
    local r=$exp_row c=$exp_col

    move_to $r $c
    printf '%s┌' "$C_BORDER"
    printf '─%.0s' $(seq 1 $exp_inner_w)
    printf '┐%s' "$C_RESET"

    local row
    for (( row=1; row<=exp_inner_h; row++ )); do
        move_to $(( r + row )) $c
        printf '%s│%s' "$C_BORDER" "$C_RESET"
        move_to $(( r + row )) $(( c + exp_inner_w + 1 ))
        printf '%s│%s' "$C_BORDER" "$C_RESET"
    done

    move_to $(( r + exp_inner_h + 1 )) $c
    printf '%s└' "$C_BORDER"
    printf '─%.0s' $(seq 1 $exp_inner_w)
    printf '┘%s' "$C_RESET"
}

# ── Draw exploded pixel view for a bitmask value ──────────────────────────────
# Bit layout: pixel(col,row) is ON when (bitmask >> (row + col*4)) & 1
# col: 0=left,1=right  row: 0=top..3=bottom
draw_exploded() {
    local bitmask="${1:-0}"
    local px_col px_row bit screen_r screen_c colour

    for (( px_row=0; px_row<4; px_row++ )); do
        for (( px_col=0; px_col<2; px_col++ )); do
            bit=$(( (bitmask >> (px_row + px_col * 4)) & 1 ))
            colour=$( (( bit )) && echo "$C_PIXEL_ON" || echo "$C_PIXEL_OFF" )

            screen_r=$(( exp_row + 1 + px_row * PIXEL_H ))
            screen_c=$(( exp_col + 1 + px_col * PIXEL_W ))

            # Fill PIXEL_H rows × PIXEL_W cols for this pixel cell
            local pr
            for (( pr=0; pr<PIXEL_H; pr++ )); do
                move_to $(( screen_r + pr )) $screen_c
                printf '%s' "$colour"
                printf ' %.0s' $(seq 1 $PIXEL_W)
                printf '%s' "$C_RESET"
            done
        done
    done
}

# ── Draw a single cell at box position (bx, by) ──────────────────────────────
draw_cell() {
    local bx=$1 by=$2
    local ax=$(( vp_x + bx ))
    local ay=$(( vp_y + by ))
    local key="${ax},${ay}"
    local char fg bg=""

    if [[ -v nbp_CAAC[$key] ]]; then
        char="${nbp_CAAC[$key]}"
        fg=""
    else
        char="$MISSING_CHAR"
        fg="$C_MISSING"
    fi

    (( bx == cx && by == cy )) && bg="$C_CURSOR_BG"

    move_to $(( box_row + 1 + by )) $(( box_col + 1 + bx * cell_w ))
    printf '%s%s%s%s' "$bg" "$fg" "$char" "$C_RESET"
}

# ── Draw all cells ────────────────────────────────────────────────────────────
draw_all_cells() {
    local bx by
    for (( by=0; by<BOX_H; by++ )); do
        for (( bx=0; bx<BOX_W; bx++ )); do
            draw_cell $bx $by
        done
    done
}

# ── Draw status lines and exploded view ───────────────────────────────────────
draw_status() {
    local ax=$(( vp_x + cx ))
    local ay=$(( vp_y + cy ))
    local key="${ax},${ay}"
    local caav_val caac_char bin_str cpinfo

    if [[ -v nbp_CAAV[$key] ]]; then
        caav_val="${nbp_CAAV[$key]}"
        bin_str=$(to_binary_coloured "$caav_val")
    else
        caav_val="(none)"
        bin_str="${C_MISSING}--------${C_RESET}"
    fi

    if [[ -v nbp_CAAC[$key] ]]; then
        caac_char="${nbp_CAAC[$key]}"
        cpinfo=$(char_info "$caac_char")
    else
        caac_char="$MISSING_CHAR"
        cpinfo="—"
    fi

    # Line 1: position / CAV / char / codepoint+font
    move_to $status_row $box_col
    clear_eol
    printf '%sPos:%s %s(%d,%d)%s  %sCAV:%s %s%-6s%s  %sChar:%s %s%s%s  %s%s%s' \
        "$C_LABEL" "$C_RESET" \
        "$C_COORD" "$ax" "$ay" "$C_RESET" \
        "$C_LABEL" "$C_RESET" \
        "$C_VALUE" "$caav_val" "$C_RESET" \
        "$C_LABEL" "$C_RESET" \
        "$C_CHAR" "$caac_char" "$C_RESET" \
        "$C_COORD" "$cpinfo" "$C_RESET"

    move_to $(( status_row + 1 )) $box_col; clear_eol

    # Line 2: bitmask
    move_to $status_bits_row $box_col
    clear_eol
    printf '%sBits:%s %s' "$C_LABEL" "$C_RESET" "$bin_str"

    move_to $(( status_bits_row + 1 )) $box_col; clear_eol

    # Line 3: array bounds / navigation hint
    move_to $status_hint_row $box_col
    clear_eol
    printf '%sArray X:%s %s%d–%d%s  %sY:%s %s%d–%d%s  %sArrows%s=navigate  %sq%s=quit' \
        "$C_LABEL" "$C_RESET" \
        "$C_COORD" "$arr_min_x" "$arr_max_x" "$C_RESET" \
        "$C_LABEL" "$C_RESET" \
        "$C_COORD" "$arr_min_y" "$arr_max_y" "$C_RESET" \
        "$C_VALUE" "$C_RESET" \
        "$C_VALUE" "$C_RESET"

    # Exploded view: use CAV bitmask if available, else 0
    local bitmask=0
    [[ -v nbp_CAAV[$key] ]] && bitmask="${nbp_CAAV[$key]}"
    draw_exploded "$bitmask"
}

# ── Key reader ────────────────────────────────────────────────────────────────
read_key() {
    local key
    IFS= read -rsn1 key
    if [[ "$key" == $'\x1b' ]]; then
        local s1 s2
        IFS= read -rsn1 -t 0.1 s1
        IFS= read -rsn1 -t 0.1 s2
        key="${key}${s1}${s2}"
    fi
    case "$key" in
        $'\x1b[A') echo "UP"    ;;
        $'\x1b[B') echo "DOWN"  ;;
        $'\x1b[C') echo "RIGHT" ;;
        $'\x1b[D') echo "LEFT"  ;;
        q|Q)        echo "QUIT"  ;;
        *)          echo "OTHER" ;;
    esac
}

# ── Move cursor, scrolling viewport at edges ──────────────────────────────────
move_cursor() {
    local dir=$1
    local prev_cx=$cx prev_cy=$cy
    local full_redraw=0

    case "$dir" in
        RIGHT)
            if (( cx < BOX_W - 1 )); then
                (( cx++ ))
            elif (( vp_x + BOX_W - 1 < arr_max_x )); then
                (( vp_x++ ))
                full_redraw=1
            fi
            ;;
        LEFT)
            if (( cx > 0 )); then
                (( cx-- ))
            elif (( vp_x > arr_min_x )); then
                (( vp_x-- ))
                full_redraw=1
            fi
            ;;
        DOWN)
            if (( cy < BOX_H - 1 )); then
                (( cy++ ))
            elif (( vp_y + BOX_H - 1 < arr_max_y )); then
                (( vp_y++ ))
                full_redraw=1
            fi
            ;;
        UP)
            if (( cy > 0 )); then
                (( cy-- ))
            elif (( vp_y > arr_min_y )); then
                (( vp_y-- ))
                full_redraw=1
            fi
            ;;
    esac

    if (( full_redraw )); then
        draw_all_cells
    else
        draw_cell $prev_cx $prev_cy
        draw_cell $cx $cy
    fi
    draw_status
}

# ── Cleanup on exit ───────────────────────────────────────────────────────────
cleanup() {
    cursor_show
    clear_screen
    move_to 1 1
    tput rmcup 2>/dev/null
    rm -f "$_FONT_INDEX_FILE"
    echo "nbp_viewer exited."
}
trap cleanup EXIT INT TERM

# ── Main ──────────────────────────────────────────────────────────────────────
tput smcup 2>/dev/null
cursor_hide
clear_screen

draw_border
draw_exp_border
draw_all_cells
draw_status

while true; do
    key=$(read_key)
    case "$key" in
        UP|DOWN|LEFT|RIGHT) move_cursor "$key" ;;
        QUIT) break ;;
    esac
done
