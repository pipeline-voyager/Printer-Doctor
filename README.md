# Printer Troubleshooting Toolkit

A PowerShell-based Terminal User Interface (TUI) for performing common printer troubleshooting, diagnostics, configuration, and network connectivity checks directly from the Windows terminal.

The tool is designed for IT support technicians, system administrators, help desk personnel, and anyone who needs a quick way to troubleshoot printers without navigating through multiple Windows configuration panels.

## Features

### Printer Management

<table>
  <tr>
    <th>Printer Features</th>
    <th>Printer Features</th>
    <th>Printer Features</th>
  </tr>
  <tr>
    <td>Detect installed printers</td>
    <td>List all installed printers</td>
    <td>Select an active printer</td>
  </tr>
  <tr>
    <td>Display current printer information</td>
    <td>View printer status</td>
    <td>View printer state</td>
  </tr>
  <tr>
    <td>View printer driver</td>
    <td>View printer port</td>
    <td>View printer location</td>
  </tr>
  <tr>
    <td>View printer comment</td>
    <td>View printer share name</td>
    <td>Refresh printer information</td>
  </tr>
  <tr>
    <td colspan="3" align="center">Set the current printer</td>
  </tr>
</table>

![Printer TUI](asset/printer_management.png)

### Printer Diagnostics

Perform common printer troubleshooting checks from a single interface.

Available diagnostic options include:

<table>
  <tr>
    <th>Printer Diagnostics</th>
    <th>Printer Diagnostics</th>
    <th>Printer Diagnostics</th>
  </tr>
  <tr>
    <td>Printer status check</td>
    <td>Printer availability check</td>
    <td>Printer queue check</td>
  </tr>
  <tr>
    <td>Print spooler check</td>
    <td>Printer driver check</td>
    <td>Printer port check</td>
  </tr>
  <tr>
    <td>Printer configuration check</td>
    <td>Network connectivity check</td>
    <td>TCP connectivity test</td>
  </tr>
  <tr>
    <td>IP address test</td>
    <td>DNS/hostname test</td>
    <td>Ping test</td>
  </tr>
  <tr>
    <td>Printer port connectivity</td>
    <td colspan="2" align="center">Printer information report</td>
  </tr>
</table>

### Driver Checking

The driver diagnostic section can be used to inspect printer driver information.

Features include:

<table>
  <tr>
    <th>Printer Driver</th>
    <th>Printer Driver</th>
    <th>Printer Driver</th>
  </tr>
  <tr>
    <td>Display installed printer driver</td>
    <td>Check driver name</td>
    <td>Check driver version</td>
  </tr>
  <tr>
    <td>Check driver provider</td>
    <td>Check driver environment</td>
    <td>Check driver architecture</td>
  </tr>
  <tr>
    <td>Identify missing driver information</td>
    <td colspan="2" align="center">Refresh driver information</td>
  </tr>
</table>

This can be useful when troubleshooting:

<table>
  <tr>
    <th>Printer Driver Issues</th>
    <th>Printer Driver Issues</th>
    <th>Printer Driver Issues</th>
  </tr>
  <tr>
    <td>Incorrect printer drivers</td>
    <td>Old drivers</td>
    <td>Generic drivers</td>
  </tr>
  <tr>
    <td>Driver installation problems</td>
    <td colspan="2" align="center">Printing failures caused by driver issues</td>
  </tr>
</table>

![Printer TUI](asset/driver_checking.png)

### Network Troubleshooting

The network troubleshooting section provides tools for investigating network printers.

Features include:

<table>
  <tr>
    <th>Network Connectivity</th>
    <th>Network Connectivity</th>
    <th>Network Connectivity</th>
  </tr>
  <tr>
    <td>Ping printer IP</td>
    <td>Test hostname connectivity</td>
    <td>Test TCP connectivity</td>
  </tr>
  <tr>
    <td>Check printer IP address</td>
    <td>Check printer port</td>
    <td>Test common printer ports</td>
  </tr>
  <tr>
    <td>Test custom TCP ports</td>
    <td>Resolve printer hostname</td>
    <td>Display network configuration</td>
  </tr>
  <tr>
    <td colspan="3" align="center">Check connection status</td>
  </tr>
</table>

![Printer TUI](asset/network.png)

Common printer ports can include:

| Port | Protocol | Common Usage |
|------|----------|--------------|
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |
| 515 | TCP | LPR/LPD |
| 631 | TCP | IPP |
| 9100 | TCP | RAW / JetDirect |
| 161 | UDP | SNMP |

### Printer Port Diagnostics

Inspect the Windows printer port associated with the selected printer.

Information may include:

<table>
  <tr>
    <th>Printer Port Information</th>
    <th>Printer Port Information</th>
    <th>Printer Port Information</th>
  </tr>
  <tr>
    <td>Port name</td>
    <td>Port type</td>
    <td>IP address</td>
  </tr>
  <tr>
    <td>Host address</td>
    <td>Protocol</td>
    <td>Port configuration</td>
  </tr>
  <tr>
    <td colspan="3" align="center">Network printer information</td>
  </tr>
</table>

![Printer TUI](asset/port.png)

Useful for identifying problems such as:

<table>
  <tr>
    <th>Printer Port Issues</th>
    <th>Printer Port Issues</th>
    <th>Printer Port Issues</th>
  </tr>
  <tr>
    <td>Incorrect IP address</td>
    <td>Wrong printer port</td>
    <td>Printer moved to another IP</td>
  </tr>
  <tr>
    <td>Offline network printer</td>
    <td>Incorrect RAW port</td>
    <td>Incorrect LPR configuration</td>
  </tr>
</table>

### Print Spooler Troubleshooting

The tool can inspect the Windows Print Spooler service.

Features include:

<table>
  <tr>
    <th>Print Spooler Management</th>
    <th>Print Spooler Management</th>
    <th>Print Spooler Management</th>
  </tr>
  <tr>
    <td>Check Print Spooler status</td>
    <td>Start Print Spooler</td>
    <td>Stop Print Spooler</td>
  </tr>
  <tr>
    <td>Restart Print Spooler</td>
    <td>Display service information</td>
    <td>Check service startup configuration</td>
  </tr>
</table>

![Printer TUI](asset/spooler.png)

The Print Spooler is one of the most common causes of Windows printing problems.

### Printer Queue

Inspect the print queue of the selected printer.

Features can include:

<table>
  <tr>
    <th>Printer Queue Management</th>
    <th>Printer Queue Management</th>
    <th>Printer Queue Management</th>
  </tr>
  <tr>
    <td>Display queued jobs</td>
    <td>Show job status</td>
    <td>Show document names</td>
  </tr>
  <tr>
    <td>Show job owner</td>
    <td>Show job size</td>
    <td>Show submission time</td>
  </tr>
  <tr>
    <td>Refresh queue</td>
    <td colspan="2" align="center">Clear printer queue</td>
  </tr>
</table>

![Printer TUI](asset/queue.png)

Queue troubleshooting can help resolve:

<table>
  <tr>
    <th>Printer Queue Issues</th>
    <th>Printer Queue Issues</th>
    <th>Printer Queue Issues</th>
  </tr>
  <tr>
    <td>Stuck print jobs</td>
    <td>Documents that never print</td>
    <td>Jobs stuck in "Printing"</td>
  </tr>
  <tr>
    <td colspan="3" align="center">Jobs stuck in "Deleting" &nbsp;&nbsp;&nbsp; Printer queue congestion</td>
  </tr>
</table>

### Printer Configuration

The configuration section provides access to common printer information and configuration.

Depending on the printer and Windows configuration, the tool can inspect:

<table>
  <tr>
    <th>Printer Information</th>
    <th>Printer Information</th>
    <th>Printer Information</th>
  </tr>
  <tr>
    <td>Printer name</td>
    <td>Driver</td>
    <td>Port</td>
  </tr>
  <tr>
    <td>Location</td>
    <td>Comment</td>
    <td>Shared status</td>
  </tr>
  <tr>
    <td>Published status</td>
    <td>Default printer status</td>
    <td>Printer state</td>
  </tr>
  <tr>
    <td colspan="3" align="center">Printer attributes</td>
  </tr>
</table>

## Installation

Clone or download the project and place the PowerShell script in a convenient directory.

Example:

```powershell
git clone https://github.com/pipeline-voyager/Printer-Doctor.git

cd Printer-Doctor/
```

No additional PowerShell modules or external dependencies are required beyond the Windows components used by the toolbox.

## Running

Open PowerShell and execute:

```powershell
.\PrinterDoctor.ps1
```

## User Interface

The application uses a keyboard-driven TUI.

![Printer TUI](asset/TUI.png)

## Author

Carl Lazaro

`@pipeline-voyager`

## Version

Version 1.0
