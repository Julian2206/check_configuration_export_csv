# 🛡️ System Configuration Checker (PowerShell)

This project is a modular PowerShell script that automatically analyzes and verifies the configuration state of a Windows system, generating a **detailed report** in both `.txt` and `.csv` formats.

## 📋 Key Features

- Checks computer name and execution policy
- Detects if USB ports are disabled
- Retrieves BIOS, OS, and Windows license information
- Collects hardware and network data (IP, partitions, RAM, CPU, drivers, installed software)
- Verifies firewall status and active rules
- Checks NTP time synchronization
- Verifies enabled/disabled services based on `config.json`
- Detects local users, missing policies, and items requiring manual review

## 📁 Project Structure

```
check_configuration_ps1/
│
├── config.json                 # Configuration for services and expected computer name
├── check_configuration.ps1    # Main script
├── NetworkConfig.psm1         # Network and IP module
├── HardwareData.psm1          # Hardware and storage module
├── Services.psm1              # Module for enabling/disabling services
├── Security.psm1              # USB, firewall, and logging module
├── RegionalSettings.psm1      # Locale, timezone, and NTP module
```

## 📦 Output

The script generates the following files in the current directory:

- `computername.txt` – Full text report
- `computername.csv` – Structured report for analysis or import

## 🛠️ Requirements

- PowerShell 5.1+ on Windows 10
- Administrator privileges (for some checks)
- All `.psm1` modules must be in the same directory as the main script

## ⚠️ Required Permissions

To run the script, you need to set the execution policy to `Bypass` for the current session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\check_configuration.ps1
```

Or run it in one line:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\check_configuration.ps1
```

## ▶️ Running the Script

```powershell
.\check_configuration.ps1
```

## 📌 Notes

- Some checks are marked for **manual review**.
- This script is designed for system configuration and security audits in IT and sysadmin environments.

## 📄 License

This project is licensed under the MIT License.
