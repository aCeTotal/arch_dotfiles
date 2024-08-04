#!/usr/bin/env bash

set -e

# Funksjoner for farger og utskrift
BOLD='\e[1m'
BRED='\e[91m'
BBLUE='\e[34m'  
BGREEN='\e[92m'
BYELLOW='\e[93m'
RESET='\e[0m'

info_print() {
    echo -e "${BOLD}${BGREEN}[ ${BYELLOW}•${BGREEN} ] $1${RESET}"
}

error_print() {
    echo -e "${BOLD}${BRED}[ ${BBLUE}•${BRED} ] $1${RESET}"
}

# Funksjon for å liste opp snapshots
list_snapshots() {
    SNAPSHOT_PATH="/mnt/.snapshots"
    if [ ! -d "$SNAPSHOT_PATH" ]; then
        error_print "Ingen snapshots funnet i $SNAPSHOT_PATH"
        exit 1
    fi

    echo "Tilgjengelige snapshots:"
    ls "$SNAPSHOT_PATH" | grep -E '^[0-9]+$'
}

# Funksjon for å laste inn snapshot med lese- og skriverettigheter
load_snapshot() {
    local snapshot_id="$1"
    local snapshot_path="/mnt/.snapshots/$snapshot_id/snapshot"
    local mount_point="/mnt/snapshot_$snapshot_id"

    if [ ! -d "$snapshot_path" ]; then
        error_print "Snapshot $snapshot_id finnes ikke."
        exit 1
    fi

    info_print "Monterer snapshot $snapshot_id med lese- og skriverettigheter på $mount_point"
    sudo mkdir -p "$mount_point"
    sudo btrfs subvolume snapshot "$snapshot_path" "$mount_point"

    info_print "Snapshot $snapshot_id er nå montert med lese- og skriverettigheter på $mount_point"

    # Bytte ut det nåværende systemet med snapshot-en
    info_print "Bytter ut det nåværende systemet med snapshot $snapshot_id"
    sudo mount --bind "$mount_point" /mnt
    sudo mount --make-rprivate /mnt
    sudo chroot /mnt /bin/bash
}

# Hovedskript
list_snapshots

echo
read -p "Skriv inn ID-en til snapshot-en du vil bruke: " snapshot_id

if [ -z "$snapshot_id" ]; then
    error_print "Du må skrive inn en snapshot ID."
    exit 1
fi

load_snapshot "$snapshot_id"
