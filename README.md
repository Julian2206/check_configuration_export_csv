# System Configuration Checker (PowerShell)

Questo progetto è uno script PowerShell modulare che analizza e verifica automaticamente lo stato di configurazione di un sistema Windows, generando un **report dettagliato** in formato `.txt` e `.csv`.

## Funzionalità principali

- Verifica nome computer e policy di esecuzione
- Controllo porte USB disabilitate
- Informazioni su BIOS, OS, licenza Windows
- Dati hardware e rete (IP, partizioni, RAM, CPU, driver, software installati)
- Stato del firewall e regole attive
- Controllo sincronizzazione oraria NTP
- Verifica servizi da abilitare/disabilitare secondo file `config.json`
- Rileva utenti locali, policy mancanti e controlli manuali

## Struttura del progetto

```
check_configuration_ps1/
│
├── config.json                # Configurazione servizi e computer name
├── check_configuration.ps1    # Script principale
├── NetworkConfig.psm1         # Modulo: rete e IP
├── HardwareData.psm1          # Modulo: hardware e storage
├── Services.psm1              # Modulo: servizi da attivare/disattivare
├── Security.psm1              # Modulo: USB, firewall, logging
├── RegionalSettings.psm1      # Modulo: lingua, fuso orario, NTP
```

## Output generato

Lo script genera nella cartella corrente:

- `nomecomputer.txt` – Report testuale completo
- `nomecomputer.csv` – Report tabellare per analisi o importazione

## Requisiti

- PowerShell 5.1+ su Windows 10
- Permessi da amministratore (per alcune verifiche)
- I moduli `.psm1` devono essere presenti nella stessa directory

## Permessi richiesti

Per eseguire questo script, è necessario impostare l'execution policy a `Bypass` (solo per la sessione corrente):

````powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\check_configuration.ps1


## Esecuzione

```powershell
.\check_configuration.ps1
````

## Note

- Alcuni controlli sono evidenziati per **verifica manuale**.
- Lo script è pensato per analisi di sicurezza/configurazione in ambito sistemistico o audit.

## Licenza

Questo progetto è distribuito sotto licenza MIT.
