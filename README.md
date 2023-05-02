

# Honeypot Hardening & Deployment with Dionaea
## Struttura
La struttura di questo deployment prevede una macchina host e una macchina virtuale contenuta al suo interno, questo permete un monitoring costante dell'honeypot ([Dionaea](https://github.com/DinoTools/dionaea)) contenuto nella VM, i vari script e tool che susseguono sono di nostra produzione e mirati al confinamento dell'attaccante al software dell'honeypot.
## Prerequisiti
Si assume che la macchian host e la VM contenuta utilizzino UBUNTU 18.04 LTS, le risorse HW richeiste per l'esecuzione della VM sono di almeno 8Gb RAM e 4 vCpu.
Gli alert e i comandi per gestire i meccanismi di difesa utilizzano un bot telegram, quindi procedere alla creazione di un Bot e un canale telegram dove aggiungerlo così da salvare Token e chat ID ([Guida](https://medium.com/geekculture/generate-telegram-token-for-bot-api-d26faf9bf064)) 
Una volta ottenuti chat id e Bot token inserirli nelle variabili predisposte di sender.sh,
che si occupa di solo di interfacciarsi con l'api di telegram successivamente copiarlo in /usr/bin  e poi chmod +x
## Monioting dell'host
### Rilevare gli accessi ssh
Per **rilevare gli accessi ssh** effettuati con successo sulla macchina host ( che non utilizzera la porta 22 poichè utilizzata di dionaea) utilizzare lo script di notifica "login-notify.sh" da copiare nella directory /etc/profile.d 
la directory contiene gli script eseguiti ad ogni login ssh con successo, se la directory non esiste, sul server ssh installato non è configurata, quindi configurarla oppure utilizzare "login-notify1.sh" che si basa sui log di sistema.
In questo caso copiare login-notify1 su /usr/sbin e proteggere lo script, come root effettuare chmod 700. Successivamente aggiungere lo script a crontab (solo nel caso di login-notify1.sh) : 

 1. Crontab -e
 2. Selezionare un editor
 3. Aggiungere al crontab @reboot nohup /usr/sbin/login-notify1.sh & > /dev/null 2>&1 &

Adesso ad ogni accesso ssh arriverà una notifica telegram contente utente e ip sorgente

### Rilevare i comandi sudo 

Per **rilevare i comandi sudo** effettuati nella macchina host utilizzare lo script di notifica "sudoNotify.sh" da copiare nella directory /usr/sbin, una volta effettuato questo utilizzare chmod 700 come root per proteggere lo script. Successivamente aggiungere lo script a crontab:
 1. Crontab -e
 2. Aggiungere al crontab @reboot nohup /usr/sbin/sudoNotify.sh & > /dev/null 2>&1 &
Adesso ad ogni comando superuser si riceverà un messaggio telegram con specificato il comando eseguito el'utente

## Installazione di un ambiente desktop e vnc 
Per comodità  installare un ambiente desktop e un server vnc per utilizzare e configurare virtualbox e la vm contenuta in esso ( noi abbiamo utilizzato XFCE4 + tightvnc come in questa [guida](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-vnc-on-ubuntu-18-04)) Oppure utilizzare Xming 


## Installazione della VM
 ### Configurazione di VirtualBox
 1. Installare l'ultima versione di VirtualBox 
 2. Connettersi con VNC all'host
 3. Scaricare ubuntu 18.04 LTS server e procedere alla normale installazione chiamano la VM HON1
 4. Dedicare almeno 4Gb Ram/ 2 Cpu
 5. Sulle impostazioni della VM di Virtualbox : System > Abilitare Enable I/O APIC
 6. Sull'host: sudo mkdir /ctrl   e   sudo mkdir /ctrl1 
 7.  Sulle impostazioni della VM di Virtualbox : Shared Folders > Add New > Folder path /ctrl, folder name: ctrl, flaggare Auto-mount > ok  
 8. Sulle impostazioni della VM di Virtualbox : Shared Folders > Add New > Folder path /ctrl1, folder name: ctrl1, flaggare Auto-mount > ok  
 9. Installata la VM installare gli additional tools di virtualbox dal CD virtuale ([Guida](https://www.techrepublic.com/article/how-to-install-virtualbox-guest-additions-on-a-gui-less-ubuntu-server-host/))
 10. Verificare che il sistema delle directory condivise funzioni ( sudo touch /media/sf_ctrl/prova)
 11. Spegnere la VM
 #### Configurazione  della nat VirtualNetwork
 sulla home gui di virtualbox 
 1. Hon1 > Settings > Network > Adapter 1 NAT > advanced : Port forwarding impostare regole di forwarding desiderate (da ip locale dell host) a Guest ip 10.0.2.15
 2. Per permettere il mantenimento degli ip sorgente eseguire il comando VBoxManage modifyvm HON1 --nataliasmode1 proxyonly dal terminale dell'host
 3. Configurare nella VM la scheda di rete di virtualbox  assegnando ip 10.0.2.15 


## Monitoring del Client
### Sistema automatico di confinamento degli attacchi
Nell'eventulità remota che un attaccante riesca a uscire dall'ambiente virtualizzato da Dioneae honeypot abbiamo prodotto qusto sistema che ad ogni comando sudo mette in pausa la vm dall'host. Il funzionamento si basa su uno scambio di messaggi tra host e client tramite la directory condivisa.
Sull Host:
 1. Copiare lo sript honAgent.sh su /usr/local/sbin/honAgent.sh
 2. sudo chmod 700 honAgent.sh 
 3. Crontab -e  > aggiungere : 
  @reboot nohup /usr/local/sbin/honAgent.sh > /dev/null 2>&1 &

Sulla VM:
1. Copiare lo script setup.sh in /usr/sbin 
2. chmod 700 setup.sh 
3. Corntab -e > aggiungere : 
	@reboot nohup /usr/local/sbin/setup.sh > /dev/null 2>&1 &

Funzionamento: Lo script sulla host machine mette in pausa la vm ogni volta che si prova ad effettuare un comando sudo sulla vm , i comandi da inviare in chat privata al bot telegram collegato sono:

- /1on per abilitare la defence mode 
- /1off per disabilitare la defence mode
- /1r per far riprendere l'esecuzione della vm

ogni volta che un evento soprastante avviene, lo script notifica tramite un messaggio sul canale telgram.
Quindi per operare sulla macchina da ora in poi eseguire /1off e solo alla fine inviare /1on
### Integrazione con Promethes di Dionaea
L'integrazione tra l'honeypot e Prometheus avviene tramite un [Promethes client](https://github.com/prometheus/client_python) scritto in python sulla macchina host, che riceve i log in fomato json dall'honeypot nella cartella condivisa ctrl1, lo script non solo monitora le varie conessioni e tipi di protocollo, ma anche le performance della macchina virtuale estraendo le statistiche da virtualbox, quindi monitora:

- Cpu usage della VM (gauge)
- Ram usage della VM
- No FTP Connections (FTPD)
- No SMB Attacks
- No SSH Attacks 
- No HTTP connections (HTTPd)
- No MySql Attacks

Sull'host:

 1. Installare Prometheus
 2. Importare il file di configurazione "prometheus.yml" al posto di /etc/prometheus/prometheus.yml  
 3. impostare un crontab per prometheus al reboot
 4. installare la libreria pip prometheus-client 
       pip install prometheus-client
  5. Copiare il file prometheusClient.py in /usr/local/sbin
  6. impostare una password per prometheus (se necessario)
  7. settare un crontab per avviarlo ad ogni riavvio:
        @reboot nohup python prometheusClient.py > /dev/null 2>&1 &
 (di default lo script raccoglie le metriche ogni 30 secondi)
 8. Configurare le metriche prestazionali di virtualbox con il comando VBoxManage metrics setup HON1 Guest/CPU/Load,Guest/RAM/Usage


Sul client, con Dionaea Installato (come descritto dopo):
1. controllare che in /opt/Dionaea/etc/dionaea/ihandlers-enabled vi sia il file log_sqlite.yaml (di defaul dovrebbe esserci) alternativamente [impostare](https://dionaea.readthedocs.io/en/latest/ihandler/log_sqlite.html) l'ihandler di sqlite.
2. scaricare https://github.com/eval2A/dionaeaToJSON:
$ wget https://raw.githubusercontent.com/eval2A/dionaeaToJSON/master/dionaeaSqliteToJson.py 
$ sudo mv dionaeaSqliteToJson.py /opt/
3. nel file scaricato configurare le variabili dionaeaSQLite = /opt/dionaea/var/lib/dionaea/dionaea.sqlite ; dionaeaLogPath = '/opt/dionaea/var/log/dionaea/json'
4. Copiare lo script "statsUpdate.sh" su usr/sbin
5. Appendere alla config crontab della vm l'exec dei due script ogni minuto:
" * * * * * nohup /usr/sbin/statsUpdate.sh > /dev/null 2>&1 & " 
 " * * * * * nohup python /opt/dionaeaSqliteToJson.py > /dev/null 2>&1 & "
 


Adesso su Prometheus (localhost:9090) dovrebbero essrvi le nuove metriche disponibili, quando un nuovo protocollo suppotato da dionaea viene attaccatto la metrica verrà aggiunta a quelle precedenti.
## 2FA google sulla vm (opzionale)
Per avere un altro layer di sicurezza sulla vm installare e configurare il modulo di autenticazione a 2 fattori di google per linux (https://www.digitalocean.com/community/tutorials/how-to-configure-multi-factor-authentication-on-ubuntu-18-04) 
# Installazione di Dionaea Honeypot senza console centralizzata
Dionaea è un mid-interaction honeypot scritto in python da installare nella vm preparata precedentemente  

* Installare Dionaea come da [documentazione](https://dionaea.readthedocs.io/en/latest/installation.html)
* Di default dionaea viene installato su /opt/dionaea e prevede la maggior parte dei servizi abilitati, verificare che il path sia giusto e i servizi abilitati, questi possono essere modificati e visualizzati nella directory : /opt/dionaea/etc/dionaea/services-enabled all'interno vi sono i file yaml di configurazione che dovrebbero essere già pronti.
* Verificare che i servizi Ftp e SMB accettino l'upload di file
* Nella directory /opt/dionaea/lib/dionaea/http/root copiare la pagina html "login.html" , questo form simula una pagina di login ad un backend cosi da poter cattuare anche credenziali provate / tentativi di SQLi
* Adesso sulla pagina ip/login.html ci dovrebbe essere un finto form di login
* Per estrarre dal file di log di dionaea i dati cattuarati nel passo precedente aggiungere ad un crontab con nohup al reboot lo script "loginLog.sh" dopo averlo protetto, questo produce il file loginForm.json nella directory condivisa /ctrl1 contente username / password e timestamp.
* Lo script loginLog.sh resta in tail al file di log di Dionaea, questo file produce un quantità di righe esponenziale, quindi nel caso loginLog occupi troppe risorse rimuoverlo.
* Il file di log di Dionaea assume grandi dimensioni (circa 2gb / gg) quindi è consigliato l'utilizzo della funzione di rotazione dei log fornita "dionaea" da inserire in /etc/logrotate.d 


Path utili da conoscere per dionaea 
Logs: /opt/dionaea/var/dionaea
Captured binaries: /opt/dionaea/var/dionaea/binaries
                    oppure /opt/dionaea/var/dionaea/ftp o ... /smbd
Session transcripts: /opt/dionaea/var/dionaea/bistreams/YYYY-MM-DD

Inoltre è possibile integrare Dionaea con l'api di virus total per eseguire una scanzione dei binari caricati (https://dionaea.readthedocs.io/en/latest/ihandler/virustotal.html?highlight=virustotal)
