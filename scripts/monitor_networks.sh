#!/bin/bash

PCAP_DIR="/pcaps"
OUTPUT_DIR="/networks"
INTERVAL=5

mkdir -p "$OUTPUT_DIR"

while true; do
    echo "[`date`] Analisando pacotes..."

    for pcap_file in "$PCAP_DIR"/*.pcap; do
        [ -e "$pcap_file" ] || continue

        base_name=$(basename "$pcap_file" .pcap)
        output_file="$OUTPUT_DIR/$base_name.txt"

        echo "------ $(date) ------" >> "$output_file"

        # Extrai conversas IP: resumo bytes enviados e recebidos entre pares IP
        tshark -r "$pcap_file" -q -z conv,ip 2>/dev/null | \
          awk '/^IPv4 Conversations/,/^$/' >> "$output_file"
    done

    sleep $INTERVAL
done