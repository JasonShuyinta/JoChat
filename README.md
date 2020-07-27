<div align="center"><img src="logo/jo.png" width="175" height="150" /></div>

# JoChat :computer: :speech_balloon:

**_JoChat_** è un sistema di messaggistica istantanea ad architettura Peer-2-Peer di tipo **decentralizzata ibrida**. I nodi, che fanno parte della rete,
riescono a comunicare tra loro grazie alle informazioni comunicate dal
Server al loro lato Server (nodo_service.ol).
<br>

## Creazione e installazione di 'lib.jar' nella cartella Java Services di Jolie

**1.** Aprire un terminale nella cartella 'lib' presente in **LabSO_JoChat-master** e scrivere questo comando per creare il file.jar della cartella contenente Privata.class:

```
<< jar cvf lib.jar lib/Privata.class >>
```

**2.** Successivamente, spostare il file jar 'lib.jar' dalla cartella 'lib', presente in **LabSO_JoChat-master**, all'interno della cartella Java Services di Jolie, in modo tale che Jolie possa riconoscere Privata.class come un servizio Java che può essere utilizzato in Jolie.

## Comandi per l'utilizzo

**1.** Aprire un terminale e posizionarsi all’interno della cartella **LabSO_JoChat-master** e avviare il server tramite il comando:

```
<< jolie server.ol >>
```

**2.** Aprire un altro terminale nella stessa cartella e avviare il monitor con il comando:

```
<< jolie monitor.ol >>
```

**3.** Aprire un altro terminale nella stessa cartella e avviare un nodo tramite il comando:

```
<< jolie nodo.ol <nomeNodo> <numeroPorta> >>
```

Ad esempio:

```
jolie nodo.ol MarcoRossi 9010
```

(Per creare N nodi, aprire N terminali e ripetere N volte il comando sopraccitato.)
