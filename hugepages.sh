#!/bin/bash
# hugepages.sh
# Manage huge pages (status, enable, disable) for 1G and 2M sizes

HP_SYS_1G_DIR="/sys/kernel/mm/hugepages/hugepages-1048576kB"
HP_SYS_2M_DIR="/sys/kernel/mm/hugepages/hugepages-2048kB"

print_usage() {
    printf "Usage: %s <command> [options]\n" "$0"
    printf "\n"
    printf "Commands:\n"
    printf "  status|show              Show huge page status (default)\n"
    printf "  enable [NUM] [-s SIZE]   Enable NUM huge pages of SIZE (1G|2M)\n"
    printf "  disable [-s SIZE]        Disable huge pages of SIZE (set to 0)\n"
    printf "\n"
    printf "Options:\n"
    printf "  -s, --size SIZE          Page size: 1G or 2M (default: largest supported)\n"
    printf "  -h, --help               Show this help\n"
}

resolve_size() {
    # Echoes: 1G | 2M | NONE
    local requested_size="${1:-auto}"
    case "$requested_size" in
        auto|AUTO|Auto|"")
            if [ -d "$HP_SYS_1G_DIR" ] && grep -qw pdpe1gb /proc/cpuinfo; then
                printf "1G"
            elif [ -d "$HP_SYS_2M_DIR" ]; then
                printf "2M"
            else
                printf "NONE"
            fi
            ;;
        1G|1g)
            if [ -d "$HP_SYS_1G_DIR" ]; then printf "1G"; else printf "NONE"; fi
            ;;
        2M|2m)
            if [ -d "$HP_SYS_2M_DIR" ]; then printf "2M"; else printf "NONE"; fi
            ;;
        *)
            printf "NONE"
            ;;
    esac
}

size_to_kb() {
    local size="$1"
    if [ "$size" = "1G" ]; then
        printf "1048576"
    else
        printf "2048"
    fi
}

get_nr_path() {
    local size="$1"
    if [ "$size" = "1G" ]; then
        printf "%s/nr_hugepages" "$HP_SYS_1G_DIR"
    else
        printf "%s/nr_hugepages" "$HP_SYS_2M_DIR"
    fi
}

show_status() {
    printf "=== Huge Pages Status ===\n"
    local mem_kb
    mem_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
    if [ -n "$mem_kb" ]; then
        printf "MemAvailable: %s MiB\n" "$((mem_kb/1024))"
    fi
    local default_hp_kb
    default_hp_kb=$(awk '/Hugepagesize:/ {print $2}' /proc/meminfo)
    if [ -n "$default_hp_kb" ]; then
        printf "Default Hugepagesize: %s kB\n" "$default_hp_kb"
    fi

    if [ -d "$HP_SYS_1G_DIR" ]; then
        local total_1g free_1g
        total_1g=$(cat "$HP_SYS_1G_DIR/nr_hugepages")
        free_1g=$(cat "$HP_SYS_1G_DIR/free_hugepages" 2>/dev/null || printf "N/A")
        printf "1G pages: total=%s free=%s capacity=%s GiB\n" "$total_1g" "$free_1g" "$total_1g"
    else
        printf "1G pages: not supported\n"
    fi

    if [ -d "$HP_SYS_2M_DIR" ]; then
        local total_2m free_2m cap_mib
        total_2m=$(cat "$HP_SYS_2M_DIR/nr_hugepages")
        free_2m=$(cat "$HP_SYS_2M_DIR/free_hugepages" 2>/dev/null || printf "N/A")
        cap_mib=$((total_2m*2))
        printf "2M pages: total=%s free=%s capacity=%s MiB\n" "$total_2m" "$free_2m" "$cap_mib"
    else
        printf "2M pages: not supported\n"
    fi
}

enable_pages() {
    local num_pages="${1:-1}"
    local size="${2:-auto}"
    size=$(resolve_size "$size")
    if [ "$size" = "NONE" ]; then
        printf "[ERROR] Requested size not supported or not available.\n" >&2
        exit 1
    fi
    if ! [[ "$num_pages" =~ ^[0-9]+$ ]]; then
        printf "[ERROR] NUM_PAGES must be a non-negative integer.\n" >&2
        exit 1
    fi
    local nr_path
    nr_path=$(get_nr_path "$size")
    if [ ! -f "$nr_path" ]; then
        printf "[ERROR] Runtime allocation not supported (missing %s).\n" "$nr_path" >&2
        printf "        Consider GRUB: default_hugepagesz=%s hugepagesz=%s hugepages=%s\n" "$size" "$size" "$num_pages" >&2
        exit 1
    fi

    # Pre-flight capacity warning
    local mem_kb size_kb req_kb
    mem_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
    size_kb=$(size_to_kb "$size")
    req_kb=$((num_pages*size_kb))
    if [ -n "$mem_kb" ] && [ "$req_kb" -gt "$mem_kb" ]; then
        printf "[WARN] Request %s pages of %s exceeds MemAvailable (%s MiB > %s MiB). Attempting anyway.\n" \
            "$num_pages" "$size" "$((req_kb/1024))" "$((mem_kb/1024))" >&2
    fi

    # Read current total and compute target (additive semantics)
    local before_total target_total after_total allocated_new
    before_total=$(cat "$nr_path")
    target_total=$((before_total + num_pages))
    printf "[INFO] Requesting %s new huge page(s) (%s each). Current total=%s, target total=%s.\n" \
        "$num_pages" "$size" "$before_total" "$target_total"

    if ! printf '%s\n' "$target_total" | sudo tee "$nr_path" >/dev/null; then
        printf "[ERROR] Failed to write to %s.\n" "$nr_path" >&2
        exit 1
    fi

    # Verify result
    after_total=$(cat "$nr_path")
    allocated_new=$((after_total - before_total))
    if [ "$allocated_new" -lt "$num_pages" ]; then
        printf "[ERROR] Allocation shortfall: requested=%s, allocated=%s, final total=%s.\n" \
            "$num_pages" "$allocated_new" "$after_total" >&2
        if [ "$size" = "1G" ]; then
            printf "        1G pages often require boot-time reservation. Try GRUB: default_hugepagesz=1G hugepagesz=1G hugepages=<N>\n" >&2
        else
            printf "        Insufficient contiguous memory or kernel limits may apply.\n" >&2
        fi
        printf "        Check kernel logs: dmesg | grep -i huge | tail -n 50\n" >&2
        exit 1
    else
        printf "[OK] Allocated %s new page(s). New total=%s.\n" "$allocated_new" "$after_total"
    fi
    show_status
}

disable_pages() {
    local size="${1:-auto}"
    size=$(resolve_size "$size")
    if [ "$size" = "NONE" ]; then
        printf "[ERROR] Requested size not supported or not available.\n" >&2
        exit 1
    fi
    local nr_path
    nr_path=$(get_nr_path "$size")
    if [ ! -f "$nr_path" ]; then
        printf "[ERROR] Runtime allocation not supported (missing %s).\n" "$nr_path" >&2
        exit 1
    fi
    printf "[INFO] Disabling huge pages (size %s).\n" "$size"
    if printf '%s\n' "0" | sudo tee "$nr_path" >/dev/null; then
        printf "[OK] All %s huge pages released.\n" "$size"
    else
        printf "[ERROR] Failed to write to %s.\n" "$nr_path" >&2
        exit 1
    fi
    show_status
}

# Main logic
cmd="$1"
shift 2>/dev/null || true
case "$cmd" in
    ""|status|show)
        show_status
        ;;
    enable)
        # Defaults
        set -- "$@"
        num_pages="1"
        size="auto"
        while [ $# -gt 0 ]; do
            case "$1" in
                -s|--size)
                    size="$2"; shift 2 || break
                    ;;
                -h|--help)
                    print_usage; exit 0
                    ;;
                --)
                    shift; break
                    ;;
                -*)
                    printf "[ERROR] Unknown option: %s\n" "$1" >&2; exit 1
                    ;;
                *)
                    if [ -z "$num_pages_set" ]; then
                        num_pages="$1"; num_pages_set=1; shift
                    else
                        shift
                    fi
                    ;;
            esac
        done
        enable_pages "$num_pages" "$size"
        ;;
    disable)
        size="auto"
        while [ $# -gt 0 ]; do
            case "$1" in
                -s|--size)
                    size="$2"; shift 2 || break
                    ;;
                -h|--help)
                    print_usage; exit 0
                    ;;
                --)
                    shift; break
                    ;;
                -*)
                    printf "[ERROR] Unknown option: %s\n" "$1" >&2; exit 1
                    ;;
                *)
                    shift
                    ;;
            esac
        done
        disable_pages "$size"
        ;;
    -h|--help)
        print_usage
        ;;
    *)
        print_usage
        exit 1
        ;;
esac