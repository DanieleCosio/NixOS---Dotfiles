"""
Do all needed action for NixOS config installation
"""

import argparse
import shutil
import pathlib
import subprocess
import os
import sys
from dataclasses import dataclass
from io import BytesIO
from zipfile import ZipFile, BadZipFile
from getpass import getpass
from http.client import HTTPConnection
from base64 import b64encode

URL = "http://secrets.homeserver.lc/secrets.zip"
FULL_CONFIG_PATH = "/home/shamorn/.config/home-manager"
GLOBAL_NIX_CONFIG_PATH = "/etc/nixos/configuration.nix"
# global config imports like overlays, etc
GLOBAL_NIX_VERISIONED_CONFIG_PATH = "./derivations/global"
GLOBAL_NIX_CONFIG_BACKUP_PATH = "./global-bk"


@dataclass
class TerminalColors:
    """
    Terminal colors codes
    """

    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


@dataclass
class Subcommands:
    """
    Subcommands
    """

    UPDATE = "update"
    BACKUP = "backup"
    RESTORE = "restore"


def get_command_line_args() -> argparse.Namespace:
    """
    Get command line arguments using argparse
    """
    parser = argparse.ArgumentParser()
    subparser = parser.add_subparsers(
        dest="subcommand",
        title="Actions",
        help="update, backup, restore NixOS config.",
    )
    subparser.required = True
    update_subparser = subparser.add_parser(
        Subcommands.UPDATE, help="Update NixOS config."
    )
    backup_subparser = subparser.add_parser(
        Subcommands.BACKUP, help="Backup NixOS config."
    )
    restore_subparser = subparser.add_parser(
        Subcommands.RESTORE, help="Restore NixOS config."
    )

    # Arguments
    parser.add_argument(
        "-l",
        "--link",
        action="store",
        help="""
            Link where secrets package is
            stored (default: http://secrets.homeserver.lc/secrets.zip).
        """,
        required=False,
    )
    parser.add_argument(
        "-f",
        "--full-conf-path",
        action="store",
        help="Config path (default: ~/.config/home-manager).",
        required=False,
    )

    update_subparser.add_argument(
        "-s",
        "--secrets",
        action="store_true",
        help="Download secrets package.",
        required=False,
    )

    return parser.parse_args()


def download_secrets_package(
    username: str, password: str, zip_password: str, url: str | None = None
) -> None:
    """
    Download secrets package zip using basic auth
    """

    url = URL if url is None else url
    if "http://" in url:
        url = url.replace("http://", "")
    elif "https://" in url:
        url = url.replace("https://", "")

    parts = url.split("/")

    # Genereta basic auth token
    token = b64encode(f"{username}:{password}".encode("utf-8")).decode("ascii")

    # Make request
    request = HTTPConnection(parts[0])
    headers = {"Authorization": "Basic " + token}
    request.request("GET", "/" + parts[1], headers=headers)
    # Get response and unzip package
    res = request.getresponse()

    if res.status != 200:
        print(
            f"""
                {TerminalColors.FAIL}Error during secrets 
                package download.{TerminalColors.ENDC}\n
            """
        )
        print(f"{TerminalColors.FAIL}{res.reason}.{TerminalColors.ENDC}\n")
        sys.exit(1)

    with ZipFile(BytesIO(res.read())) as zip_file:
        try:
            zip_file.extractall("./dotfiles", pwd=zip_password.encode())
        except BadZipFile as err:
            print(
                f"""
                    {TerminalColors.FAIL}Error during secrets 
                    package extraction.{TerminalColors.ENDC}\n
                """
            )
            print(f"{TerminalColors.FAIL}{err}.{TerminalColors.ENDC}\n")
            sys.exit(1)


def backup_current_config() -> None:
    """
    Backup current NixOS configuration
    """
    config_backup_path = pathlib.Path(GLOBAL_NIX_CONFIG_BACKUP_PATH)
    backup_already_exists = config_backup_path.exists()
    backup_new_path = f"{config_backup_path}--deleting"
    if backup_already_exists:
        os.rename(config_backup_path, backup_new_path)

    config_path = pathlib.Path(GLOBAL_NIX_CONFIG_PATH).parents[0]
    shutil.copytree(config_path, config_backup_path)

    if backup_already_exists:
        shutil.rmtree(backup_new_path)


def restore_backup_config() -> None:
    """
    Restore backup NixOS configuration
    """
    config_backup_path = pathlib.Path(GLOBAL_NIX_CONFIG_BACKUP_PATH)
    config_path = pathlib.Path(GLOBAL_NIX_CONFIG_PATH).parents[0]
    for file in config_path.iterdir():
        file.unlink()

    for file in config_backup_path.iterdir():
        shutil.copy2(file, config_path)


def update_nixos_config() -> None:
    """
    Update NixOS configuration
    """
    config_path = pathlib.Path(GLOBAL_NIX_CONFIG_PATH).parents[0]
    for file in config_path.iterdir():
        file.unlink()

    shutil.copy2("./configuration.nix", GLOBAL_NIX_CONFIG_PATH)

    versioned_config_path = pathlib.Path(GLOBAL_NIX_VERISIONED_CONFIG_PATH)
    for file in versioned_config_path.iterdir():
        shutil.copy2(file, config_path)


if __name__ == "__main__":
    # Check if is script is executed as root
    if os.geteuid() != 0:
        print(f"{TerminalColors.FAIL}File must be executed as root")
        sys.exit(1)

    args = get_command_line_args()
    fullConfigPath = (
        FULL_CONFIG_PATH if args.full_conf_path is None else args.full_conf_path
    )

    # Check current path
    currentFilePath = pathlib.Path(__file__).parent.resolve()
    if str(currentFilePath) != str(fullConfigPath):
        print(
            f"""
                {TerminalColors.FAIL}File must be executed in {fullConfigPath}. 
                You can change the path using -f or --full-conf-path argument.{TerminalColors.ENDC}
            """
        )
        sys.exit(1)

    if args.subcommand == Subcommands.BACKUP:
        backup_current_config()
    elif args.subcommand == Subcommands.RESTORE:
        restore_backup_config()
    elif args.subcommand == Subcommands.UPDATE:
        if args.secrets:
            # Download and unzip secrets package
            basicAuthUsername = input("Basic auth username: ")
            basicAuthPassword = getpass("Basic auth password: ")
            zipPassword = getpass("Secrets packages passoword: ")

            download_secrets_package(
                basicAuthUsername, basicAuthPassword, zipPassword, args.link
            )

        # Copy NixOS global config
        backup_current_config()
        update_nixos_config()

        # Test and set global NixOS config
        try:
            subprocess.run("nixos-rebuild  build", shell=True, check=True)
        except subprocess.CalledProcessError as error:
            print(
                f"""
                    {TerminalColors.FAIL}Error during NixOS global 
                    configuration validation.{TerminalColors.ENDC}\n
                """
            )
            print(f"{TerminalColors.FAIL}{error}{TerminalColors.ENDC}")

            # Restore backup config if exists
            if pathlib.Path("./configuration-bk.nix").exists():
                shutil.copy2("./configuration-bk.nix", GLOBAL_NIX_CONFIG_PATH)
                os.remove("./configuration-bk.nix")

            sys.exit(1)
