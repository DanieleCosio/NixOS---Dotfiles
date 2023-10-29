"""
Do all needed action for nixos config installation
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


def get_command_line_args() -> argparse.Namespace:
    """
    Get command line arguments using argparse
    """
    parser = argparse.ArgumentParser()

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
    parser.add_argument(
        "-u",
        "--update-config",
        action="store_true",
        help="Only validate and update nix and home-manager config.",
        required=False,
    )

    return parser.parse_args()


def download_secrets_package(
    username: str, password: str, zip_password: str, url: str = None
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

    if not args.update_config:
        # Download and unzip secrets package
        basicAuthUsername = input("Basic auth username: ")
        basicAuthPassword = getpass("Basic auth password: ")
        zipPassword = getpass("Secrets packages passoword: ")

        download_secrets_package(
            basicAuthUsername, basicAuthPassword, zipPassword, args.link
        )

    # Copy nixos global config
    if pathlib.Path("/etc/nixos/configuration.nix").exists():
        shutil.copy2("/etc/nixos/configuration.nix", "./configuration-bk.nix")
        os.remove("/etc/nixos/configuration.nix")
    shutil.copy2("./configuration.nix", GLOBAL_NIX_CONFIG_PATH)

    # Test and set global nixos config
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

    # Run Home Manger config validaton and switch
    # try:
    #     subprocess.run(
    #         "home-manager build",
    #         shell=True,
    #         check=True,
    #     )
    # except subprocess.CalledProcessError as error:
    #     print(
    #         f"""
    #             {TerminalColors.FAIL}Error during NixOS global
    #             configuration validation.{TerminalColors.ENDC}\n
    #         """
    #     )
    #     print(f"{TerminalColors.FAIL}{error}{TerminalColors.ENDC}")
    #     sys.exit(1)

    # try:
    #     subprocess.run("home-manager switch", shell=True, check=True)
    # except subprocess.CalledProcessError as error:
    #     print(
    #         f"""
    #             {TerminalColors.FAIL}Error during NixOS global
    #             configuration validation.{TerminalColors.ENDC}\n
    #         """
    #     )
    #     print(f"{TerminalColors.FAIL}{error}{TerminalColors.ENDC}")
    #     sys.exit(1)
