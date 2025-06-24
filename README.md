# volta-update-all

A simple, POSIX-compliant shell script to update all tools managed by [Volta](https://volta.sh/).

## Features

- **Comprehensive Updates:** Updates all Volta-managed tools (like Node.js, npm, Yarn, and any installed global packages) to their latest versions based on your configured channels (`lts` or `latest`).
- **Safe Dry Runs:** Preview potential changes with the `--dry-run` flag before applying them.
- **Self-Update:** Optionally updates Volta itself to the latest version before updating your tools.
- **Flexible Exclusions:** Skip updates for specific tools using the `--exclude` flag.
- **Portable:** Works in any POSIX-compliant shell (e.g., `sh`, `dash`), no `bash` required.

## Prerequisites

- [Volta](https://volta.sh/) must be installed and available in your `PATH`.
- Standard Unix utilities: `curl` and a POSIX-compliant `awk` (these are included by default in macOS and most Linux distributions).
- **To update pnpm** you must export
  `export VOLTA_FEATURE_PNPM=1`
  before running the script (Volta's feature flag).

## Usage

1. Make the script executable:

   ```sh
   chmod +x volta-update-all.sh
   ```

2. Run the script:

   ```sh
   ./volta-update-all.sh
   ```

### Flags

| Flag              | Description                                         |
| ----------------- | --------------------------------------------------- |
| `--dry-run`       | Show what would change without making any installs. |
| `--self-update`   | Update Volta itself before updating other tools.    |
| `--exclude a,b,c` | Comma-separated list of tool names to skip.         |
| `-h`, `--help`    | Display the help message.                           |

### Examples

Update everything except for `yarn`:

```sh
./volta-update-all.sh --exclude yarn
```

Perform a dry run after updating Volta itself:

```sh
./volta-update-all.sh --self-update --dry-run
```

## Configuration

You can configure the update channels by modifying the variables at the top of the script:

- `NODE_CHANNEL`: The update channel for Node.js. Defaults to `lts`. Change to `latest` for the newest Node.js version.
- `DEFAULT_CHANNEL`: The update channel for all other tools. Defaults to `latest`.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

_Created by Dominik Roblek © 2025_
