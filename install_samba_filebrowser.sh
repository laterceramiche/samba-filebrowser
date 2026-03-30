#!/bin/bash
set -e

echo "=== Installazione Samba su Debian ==="
apt update && apt install -y samba

echo ""
echo "=== Configurazione utente Samba ==="
read -p "Inserisci il nome utente Samba: " SMBUSER
read -s -p "Inserisci la password Samba: " SMBPASS
echo ""
read -s -p "Conferma password: " SMBPASS2
echo ""

if [ "$SMBPASS" != "$SMBPASS2" ]; then
    echo "Le password non coincidono. Riprova."
    exit 1
fi

# Crea utente Linux se non esiste
if ! id "$SMBUSER" >/dev/null 2>&1; then
    useradd -m "$SMBUSER"
fi

# Imposta password Samba
echo -e "$SMBPASS\n$SMBPASS" | smbpasswd -a -s "$SMBUSER"

echo ""
echo "=== Creazione share Samba ==="

SHARE_PATH="/srv/samba/$SMBUSER"
mkdir -p "$SHARE_PATH"

chown "$SMBUSER":"$SMBUSER" "$SHARE_PATH"
chmod 770 "$SHARE_PATH"

echo ""
echo "=== Backup configurazione Samba ==="
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

echo "=== Scrittura nuova configurazione Samba ==="

cat << EOF > /etc/samba/smb.conf
[global]
   workgroup = WORKGROUP
   security = user
   map to guest = Bad User

[$SMBUSER]
   path = $SHARE_PATH
   browseable = yes
   read only = no
   valid users = $SMBUSER
   force user = $SMBUSER
   create mask = 0660
   directory mask = 0770
EOF

echo ""
echo "=== Riavvio Samba ==="
systemctl restart smbd

apt install curl -y

echo "=== Installazione FileBrowser ==="

bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/filebrowser.sh)"

echo ""
echo "=== INSTALLAZIONE COMPLETATA ==="
echo "Share creata:"
echo "  Percorso: $SHARE_PATH"
echo "  Utente:   $SMBUSER"
echo ""
echo "Ora puoi accedere alla share da Windows o Linux."
echo ""
echo ""
echo "FileBrowser disponibile su:"
echo "  http://<IP-DEL-SERVER>:8080"
echo "Login:"
echo "  Default user: admin"
echo "  Default community-scripts.org"
