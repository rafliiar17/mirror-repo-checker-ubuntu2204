# Mirror Installation Script

This script updates the mirror list for an Ubuntu system, selects the best mirror based on connection times, and updates the `sources.list` file accordingly. It logs detailed information about the process for both successful and failed mirror checks.

## Features

- **Backup**: Creates a backup of the current `sources.list`.
- **Mirror Fetching**: Downloads a list of available mirrors.
- **Mirror Filtering**: Filters mirrors based on their status.
- **Mirror Selection**: Tests each mirror and selects the best one based on connection time.
- **Logging**: Logs detailed information about each mirror's connectivity and the selection process.
- **Timeout**: Sets a 5-second timeout for checking each mirror.

## Requirements

- **wget**: For downloading the mirror list.
- **curl**: For testing mirror connections.
- **netselect**: For selecting the best mirror.
- **bc**: For calculating percentages.

## Installation

1. **Download the Script**: Save the `install_mirror.sh` script to your system.

2. **Make it Executable**: Run the following command to make the script executable:

   ```bash
   chmod +x install_mirror.sh
   ```

3. **Install Dependencies**: Ensure that the required tools (`wget`, `curl`, `netselect`, `bc`) are installed. If not, install them using:

   ```bash
   sudo apt update
   sudo apt install wget curl netselect bc
   ```

## Usage

To run the script, use the following command:

```bash
sudo ./install_mirror.sh
```

## Script Output

The script provides real-time updates and progress in the terminal. It also logs detailed information to a file named `log-update-mirror-YYYY-MM-DD.txt` in the `log` directory.

### Example Log

```plaintext
2024-08-12 15:15:18 -> [1] host [http://mirrors.dc.clear.net.ar/ubuntu/] : [valid] : connected on 2124ms
2024-08-12 15:15:20 -> [2] host [http://mirror.sitsa.com.ar/ubuntu/] : [valid] : connected on 2202ms
2024-08-12 15:15:22 -> [3] host [http://ubuntu.zero.com.ar/ubuntu/] : [valid] : connected on 1609ms
2024-08-12 15:15:29 -> [4] host [http://mirrors.asnet.am/ubuntu/] : [too long connecting] : 5004ms
```

## Note

- The script tests each mirror with a 5-second timeout.
- If a mirror's connection time exceeds 5000ms, it is logged as "too long connecting."

## Troubleshooting

- **`bc` Command Not Found**: Install `bc` using `sudo apt install bc`.
- **Permission Issues**: Ensure you run the script with `sudo` to have the necessary permissions.

## Contributing

Feel free to submit issues or pull requests if you find bugs or want to add features. Please ensure your changes are well-tested and documented.

## License

This script is licensed under the MIT License. See [LICENSE](LICENSE) for more details.

---

You can copy this text and paste it into your `README.md` file on GitHub. It should maintain proper formatting.
