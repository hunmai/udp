#!/bin/bash

CONFIG_DIR="/etc/hysteria"
CONFIG_FILE="$CONFIG_DIR/config.json"
USER_DB="$CONFIG_DIR/udpusers.db"
SYSTEMD_SERVICE="/etc/systemd/system/hysteria-server.service"

mkdir -p "$CONFIG_DIR"
touch "$USER_DB"

fetch_users() {
    if [[ -f "$USER_DB" ]]; then
        sqlite3 "$USER_DB" "SELECT username || ':' || password FROM users;" | paste -sd, -
    fi
}

update_userpass_config() {
    local users=$(fetch_users)
    local user_array=$(echo "$users" | awk -F, '{for(i=1;i<=NF;i++) printf "\"" $i "\"" ((i==NF) ? "" : ",")}')
    jq ".auth.config = [$user_array]" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}

add_user() {
    echo -e "\n\e[1;34mกรอกชื่อผู้ใช้:\e[0m"
    read -r username
    echo -e "\e[1;34mกรอกรหัสผ่าน:\e[0m"
    read -r password
    sqlite3 "$USER_DB" "INSERT INTO users (username, password) VALUES ('$username', '$password');"
    if [[ $? -eq 0 ]]; then
        echo -e "\e[1;32mผู้ใช้ $username เพิ่มเรียบร้อยแล้ว.\e[0m"
        update_userpass_config
        restart_server
    else
        echo -e "\e[1;31mข้อผิดพลาด: ไม่สามารถเพิ่มผู้ใช้ได้ $username.\e[0m"
    fi
}

edit_user() {
    echo -e "\n\e[1;34mกรอกชื่อผู้ใช้เพื่อแก้ไข:\e[0m"
    read -r username
    echo -e "\e[1;34mกรอกรหัสผ่านใหม่:\e[0m"
    read -r password
    sqlite3 "$USER_DB" "อัพเดทผู้ใช้ตั้งรหัสผ่าน = '$password' WHERE username = '$username';"
    if [[ $? -eq 0 ]]; then
        echo -e "\e[1;32mผู้ใช้ $username อัปเดตสำเร็จแล้ว.\e[0m"
        update_userpass_config
        restart_server
    else
        echo -e "\e[1;31mข้อผิดพลาด: ไม่สามารถอัปเดตผู้ใช้ได้ $username.\e[0m"
    fi
}

delete_user() {
    echo -e "\n\e[1;34mกรอกชื่อผู้ใช้เพื่อลบ:\e[0m"
    read -r username
    sqlite3 "$USER_DB" "ลบจากผู้ใช้ที่ชื่อผู้ใช้ = '$username';"
    if [[ $? -eq 0 ]]; then
        echo -e "\e[1;32mผู้ใช้ $username ลบสำเร็จแล้ว.\e[0m"
        update_userpass_config
        restart_server
    else
        echo -e "\e[1;31mข้อผิดพลาด: ไม่สามารถลบผู้ใช้ได้ $username.\e[0m"
    fi
}

show_users() {
    echo -e "\n\e[1;34mผู้ใช้งานปัจจุบัน:\e[0m"
    sqlite3 "$USER_DB" "เลือกชื่อผู้ใช้จากผู้ใช้;"
}

change_domain() {
    echo -e "\n\e[1;34mเข้าสู่โดเมนใหม่:\e[0m"
    read -r domain
    jq ".server = \"$domain\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mโดเมนเปลี่ยนเป็น $domain ประสบความสำเร็จ.\e[0m"
    restart_server
}

change_obfs() {
    echo -e "\n\e[1;34mป้อนสตริงการบดบังใหม่:\e[0m"
    read -r obfs
    jq ".obfs.password = \"$obfs\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mสตริงการบดบังเปลี่ยนเป็น $obfs ประสบความสำเร็จ.\e[0m"
    restart_server
}

change_up_speed() {
    echo -e "\n\e[1;34mป้อนความเร็วการอัพโหลดใหม่ (Mbps):\e[0m"
    read -r up_speed
    jq ".up_mbps = $up_speed" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    jq ".up = \"$up_speed Mbps\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mความเร็วในการอัพโหลดเปลี่ยนเป็น $up_speed Mbps สำเร็จ.\e[0m"
    restart_server
}

change_down_speed() {
    echo -e "\n\e[1;34mป้อนความเร็วในการดาวน์โหลดใหม่ (Mbps):\e[0m"
    read -r down_speed
    jq ".down_mbps = $down_speed" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    jq ".down = \"$down_speed Mbps\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mความเร็วในการดาวน์โหลดเปลี่ยนเป็น $down_speed Mbps ประสบความสำเร็จ.\e[0m"
    restart_server
}

restart_server() {
    systemctl restart hysteria-server
    echo -e "\e[1;32mเซิร์ฟเวอร์รีสตาร์ทสำเร็จแล้ว.\e[0m"
}

uninstall_server() {
    echo -e "\n\e[1;34mการถอนการติดตั้งเซิร์ฟเวอร์ SHAN VPN...\e[0m"
    systemctl stop hysteria-server
    systemctl disable hysteria-server
    rm -f "$SYSTEMD_SERVICE"
    systemctl daemon-reload
    rm -rf "$CONFIG_DIR"
    rm -f /usr/local/bin/hysteria
    echo -e "\e[1;32mถอนการติดตั้งเซิร์ฟเวอร์ SHAN VPN สำเร็จแล้ว.\e[0m"
}

show_banner() {
    echo -e "\e[1;36m---------------------------------------------"
    echo " ผู้จัดการ SHAN VPN"
    echo " (c) 2025 SHAN VPN"
    echo " Telegram: @ovpnth"
    echo "---------------------------------------------\e[0m"
}

show_menu() {
    echo -e "\e[1;36m----------------------------"
    echo " SHAN VPN UDP Script"
    echo -e "----------------------------\e[0m"
    echo -e "\e[1;32m1. เพิ่มผู้ใช้ใหม่"
    echo "2. แก้ไขรหัสผ่านผู้ใช้"
    echo "3. ลบผู้ใช้"
    echo "4. แสดงผู้ใช้"
    echo "5. เปลี่ยนโดเมน"
    echo "6. เปลี่ยนสตริงการบดบัง"
    echo "7. เปลี่ยนความเร็วในการอัพโหลด"
    echo "8. เปลี่ยนความเร็วในการดาวน์โหลด"
    echo "9. รีสตาร์ทเซิร์ฟเวอร์"
    echo "10. ถอนการติดตั้งเซิร์ฟเวอร์"
    echo -e "11. ออก\e[0m"
    echo -e "\e[1;36m----------------------------"
    echo -e "ป้อนตัวเลือกของคุณ: \e[0m"
}

show_banner
while true; do
    show_menu
    read -r choice
    case $choice in
        1) add_user ;;
        2) edit_user ;;
        3) delete_user ;;
        4) show_users ;;
        5) change_domain ;;
        6) change_obfs ;;
        7) change_up_speed ;;
        8) change_down_speed ;;
        9) restart_server ;;
        10) uninstall_server; exit 0 ;;
        11) exit 0 ;;
        *) echo -e "\e[1;31mตัวเลือกไม่ถูกต้อง กรุณาลองอีกครั้ง.\e[0m" ;;
    esac
done
